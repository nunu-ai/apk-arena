import 'package:flutter/material.dart';
import 'food_models.dart';

class FoodShopOverview extends StatelessWidget {
  final List<FoodShop> shops;
  final void Function(FoodShop) onSelect;

  const FoodShopOverview({super.key, required this.shops, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE6EBF0),
      child: Theme(
        data: ThemeData.light(),
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
              child: const Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.black87),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'choose a place',
                      style: TextStyle(
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
              itemCount: shops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = shops[index];
                return InkWell(
                  onTap: () => onSelect(s),
                  child: Container(
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
                        Text(s.emoji ?? '🍽️', style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${s.items.length} items', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black45),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    ),
  );
  }
}
