// lib/cart_item.dart

class CartItem {
  final String name;
  final String imagePath;
  final String emoji;
  final double price;
  final String description;
  final int quantity;

  CartItem({
    required this.name,
    required this.imagePath,
    required this.emoji,
    required this.price,
    required this.description,
    this.quantity = 1,
  });

  // Optional: helpful for copying with changes
  CartItem copyWith({
    String? name,
    String? imagePath,
    String? emoji,
    double? price,
    String? description,
    int? quantity,
  }) {
    return CartItem(
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      emoji: emoji ?? this.emoji,
      price: price ?? this.price,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }

  // Optional: helpful for debugging
  @override
  String toString() {
    return 'CartItem(name: $name, price: $price, quantity: $quantity)';
  }
}
