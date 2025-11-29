import 'package:flutter/material.dart';
import 'food_models.dart';

class FoodCartPanel extends StatelessWidget {
  final List<CartItem> items;
  final VoidCallback onPlaceOrder;
  final VoidCallback? onClear;

  const FoodCartPanel({super.key, required this.items, required this.onPlaceOrder, this.onClear});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (p, e) => p + e.total);
    const ueGreen = Color(0xFF06C167);
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: ueGreen),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: ueGreen, foregroundColor: Colors.white),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExpansionTile(
                leading: const Icon(Icons.shopping_bag_outlined, color: Colors.black87),
                title: Text('cart • ${items.isEmpty ? 'empty' : '${items.length} items'}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                subtitle: Text('total \$${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54)),
                children: [
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('add items to your cart', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    ...items.map((i) => ListTile(
                          dense: true,
                          title: Text('${i.item.name} ×${i.quantity}', style: const TextStyle(color: Colors.black87)),
                          subtitle: _toppingsLine(i),
                        trailing: Text('\$${i.total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black87)),
                        )),
                  const SizedBox(height: 8),
                  if (onClear != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: onClear, child: const Text('clear')),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: onPlaceOrder, child: const Text('place order')),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget? _toppingsLine(CartItem i) {
    if (i.item.toppings.isEmpty) return null;
    final removed = i.removedToppingIds;
    if (removed.isEmpty) return null;
    final labels = i.item.toppings
        .where((t) => removed.contains(t.id))
        .map((t) => 'no ${t.name.toLowerCase()}')
        .toList();
    return Text(labels.join(', '), style: const TextStyle(color: Colors.black54));
  }
}
