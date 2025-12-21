// Pure data models for food ordering UI (no icon dependency)

class FoodTopping {
  final String id;
  final String name;
  final bool defaultIncluded;

  const FoodTopping({
    required this.id,
    required this.name,
    this.defaultIncluded = true,
  });
}

class FoodItem {
  final String id;
  final String name;
  final String type; // e.g. 'pizza', 'drink'
  final double price;
  final List<FoodTopping> toppings; // empty if none
  final String? emoji; // optional emoji to render instead of icon

  const FoodItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.toppings = const [],
    this.emoji,
  });
}

class FoodShop {
  final String id;
  final String name;
  final List<FoodItem> items;
  final String? emoji; // optional emoji to render instead of icon

  const FoodShop({
    required this.id,
    required this.name,
    required this.items,
    this.emoji,
  });
}

class CartItem {
  final FoodItem item;
  final int quantity;
  final Set<String> removedToppingIds; // toppings removed from defaults

  const CartItem({
    required this.item,
    this.quantity = 1,
    this.removedToppingIds = const {},
  });

  CartItem copyWith({int? quantity, Set<String>? removedToppingIds}) => CartItem(
        item: item,
        quantity: quantity ?? this.quantity,
        removedToppingIds: removedToppingIds ?? this.removedToppingIds,
      );

  double get total => item.price * quantity;
}
