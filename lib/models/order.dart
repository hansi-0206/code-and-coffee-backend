class OrderStatus {
  static const String pending = 'pending';
  static const String preparing = 'preparing';
  static const String ready = 'ready';
  static const String completed = 'completed';
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final List<OrderItem> items;

  final double subtotal;
  final double tax;

  // 🔥 KEEP ORIGINAL
  final double total;

  // 🔥 ADD ALIAS (ADMIN FIX)
  double get totalAmount => total;

  final String status;
  final String priority;

  // 🔥 PAYMENT
  final String paymentMode;
  final String paymentStatus;
  final String? paymentOrderId;

  final DateTime createdAt;
  final DateTime? estimatedTime;

  // ================= 🔥 NEW (MULTI-CANTEEN SAFE) =================
  final String? canteenId;
  final String? canteenName;
  // ===============================================================

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.priority,
    required this.paymentMode,
    required this.paymentStatus,
    this.paymentOrderId,
    required this.createdAt,
    this.estimatedTime,

    // 🔥 ADD (OPTIONAL)
    this.canteenId,
    this.canteenName,
  });

  bool get isPending => status == OrderStatus.pending;
  bool get isPreparing => status == OrderStatus.preparing;
  bool get isReady => status == OrderStatus.ready;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isHighPriority => priority == 'high';

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'User',
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),

      // 🔥 BACKEND USES total
      total: (json['total'] ?? json['totalAmount'] ?? 0).toDouble(),

      status: json['status'] ?? OrderStatus.pending,
      priority: json['priority'] ?? 'normal',

      paymentMode: json['paymentMode'] ?? 'COD',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      paymentOrderId: json['paymentOrderId'],

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      estimatedTime: json['estimatedTime'] != null
          ? DateTime.parse(json['estimatedTime'])
          : null,

      // ================= 🔥 SAFE CANTEEN PARSING =================
      canteenId: json['canteenId'] ??
          json['canteen']?['_id'] ??
          json['canteen'],
      canteenName: json['canteenName'] ??
          json['canteen']?['name'],
      // ===========================================================
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status,
      'priority': priority,
      'paymentMode': paymentMode,
      'paymentStatus': paymentStatus,
      'paymentOrderId': paymentOrderId,
      'createdAt': createdAt.toIso8601String(),
      'estimatedTime': estimatedTime?.toIso8601String(),

      // 🔥 ADD (NON-BREAKING)
      'canteenId': canteenId,
      'canteenName': canteenName,
    };
  }

  Order copyWith({
    String? status,
    String? priority,
    DateTime? estimatedTime,
    String? paymentStatus,
  }) {
    return Order(
      id: id,
      userId: userId,
      userName: userName,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      paymentMode: paymentMode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentOrderId: paymentOrderId,
      createdAt: createdAt,
      estimatedTime: estimatedTime ?? this.estimatedTime,

      // 🔥 PRESERVE
      canteenId: canteenId,
      canteenName: canteenName,
    );
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItem'] is Map
          ? json['menuItem']['_id']
          : (json['menuItem'] ?? json['menuItemId'] ?? ''),
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  double get total => price * quantity;
}