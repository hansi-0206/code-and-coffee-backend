class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? description;
  final String? image;
  final bool available;

  // ✅ ✅ ADDED 🔥
  final int stock;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    this.image,
    this.available = true,

    // ✅ ✅ ADDED 🔥
    this.stock = 0,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
  return MenuItem(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    price: (json['price'] is int)
        ? (json['price'] as int).toDouble()
        : (json['price'] ?? 0).toDouble(),
    description: json['description'],
    image: json['image'],
    available: json['available'] ?? true,

    // 🔥 SAFER STOCK PARSING
    stock: (json['stock'] is int)
        ? json['stock']
        : int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
  );
}
}

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get total => menuItem.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItem.id,
      'quantity': quantity,
    };
  }
}
