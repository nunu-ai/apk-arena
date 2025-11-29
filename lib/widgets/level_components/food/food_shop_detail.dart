import 'package:flutter/material.dart';
import 'food_models.dart';

class FoodShopDetail extends StatelessWidget {
  final FoodShop shop;
  final void Function(CartItem) onAddToCart;
  final VoidCallback? onBack;

  const FoodShopDetail({
    super.key,
    required this.shop,
    required this.onAddToCart,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    const ueGreen = Color(0xFF06C167);
    return Material(
      color: const Color(0xFFE6EBF0),
      child: Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: ueGreen),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.store_mall_directory, color: Colors.black87),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        shop.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: shop.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = shop.items[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(item.emoji ?? '🍽️', style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('\$' + item.price.toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final result = await showModalBottomSheet<CartItem>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (_) => _CustomizationSheet(item: item),
                            );
                            if (result != null) onAddToCart(result);
                          },
                          icon: Icon(Icons.add_circle, color: ueGreen),
                          tooltip: 'add',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomizationSheet extends StatefulWidget {
  final FoodItem item;
  const _CustomizationSheet({required this.item});

  @override
  State<_CustomizationSheet> createState() => _CustomizationSheetState();
}

class _CustomizationSheetState extends State<_CustomizationSheet> {
  int _qty = 1;
  late Map<String, bool> _toppingIncluded;

  @override
  void initState() {
    super.initState();
    _toppingIncluded = {
      for (final t in widget.item.toppings) t.id: t.defaultIncluded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop<CartItem>(),
                  icon: const Icon(Icons.close, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.item.toppings.isNotEmpty) ...[
              const Text('customize', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 8),
              ...widget.item.toppings.map(
                (t) => CheckboxListTile(
                  value: _toppingIncluded[t.id] ?? true,
                  onChanged: (v) => setState(() => _toppingIncluded[t.id] = v ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.name, style: const TextStyle(color: Colors.black87)),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const Divider(),
            ],
            Row(
              children: [
                const Text('quantity', style: TextStyle(color: Colors.black87)),
                const Spacer(),
                IconButton(onPressed: () => setState(() => _qty = (_qty - 1).clamp(1, 99)), icon: const Icon(Icons.remove_circle_outline)),
                Text('$_qty', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                IconButton(onPressed: () => setState(() => _qty = (_qty + 1).clamp(1, 99)), icon: const Icon(Icons.add_circle_outline)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final removed = <String>{};
                  for (final t in widget.item.toppings) {
                    final include = _toppingIncluded[t.id] ?? true;
                    if (t.defaultIncluded && !include) removed.add(t.id);
                  }
                  Navigator.of(context).pop<CartItem>(
                    CartItem(item: widget.item, quantity: _qty, removedToppingIds: removed),
                  );
                },
                child: const Text('add to cart'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
