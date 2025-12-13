import 'package:equatable/equatable.dart';

class InventoryItem extends Equatable {
  final String id;
  final String name;
  final String sku;
  final String category;
  final String description;
  final int quantity;
  final String? location;
  final String? notes;
  final DateTime? lastUpdated;
  final DateTime? lastCounted;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.description,
    required this.quantity,
    this.location,
    this.notes,
    this.lastUpdated,
    this.lastCounted,
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    String? description,
    int? quantity,
    String? location,
    String? notes,
    DateTime? lastUpdated,
    DateTime? lastCounted,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastCounted: lastCounted ?? this.lastCounted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'description': description,
      'quantity': quantity,
      'location': location,
      'notes': notes,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'lastCounted': lastCounted?.toIso8601String(),
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      lastCounted: json['lastCounted'] != null
          ? DateTime.parse(json['lastCounted'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    sku,
    category,
    description,
    quantity,
    location,
    notes,
    lastUpdated,
    lastCounted,
  ];

  @override
  String toString() =>
      'InventoryItem(id: $id, name: $name, sku: $sku, qty: $quantity)';
}