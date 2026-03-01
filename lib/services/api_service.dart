import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/canteen.dart';
import 'storage_service.dart';

class ApiService {

  // ✅ ✅ ADDED (Fixes socket error)
  String get baseUrl => ApiConfig.baseUrl;

  /* =========================================================
     HEADERS
  ========================================================= */
  Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /* =========================================================
     SERVER WARMUP
  ========================================================= */
  Future<void> warmUp() async {
    try {
      await http
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /* =========================================================
     STATUS NORMALIZATION
  ========================================================= */
  String _normalizeStatus(String? status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.completed;
      default:
        return OrderStatus.pending;
    }
  }

  Order _mapOrder(Map<String, dynamic> json) {
    json['status'] = _normalizeStatus(json['status']);
    return Order.fromJson(json);
  }

  /* =========================================================
     AUTH
  ========================================================= */
  Future<User> login(String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user']).copyWith(token: data['token']);
      await StorageService.saveUser(user);
      return user;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  /* =========================================================
     CANTEENS
  ========================================================= */
  Future<List<Canteen>> getCanteens() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/canteens?t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Canteen.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load canteens');
    }
  }

  /* =========================================================
     MENU
  ========================================================= */
  Future<List<MenuItem>> getMenuItemsByCanteen(String canteenId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.menuItems}?canteenId=$canteenId&t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => MenuItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load menu items');
    }
  }

  Future<List<MenuItem>> getMenuItems() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.menuItems}?t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => MenuItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load menu items');
    }
  }

  Future<MenuItem> createMenuItem(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.menuItems}'),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return MenuItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create menu item');
    }
  }

  Future<MenuItem> updateMenuItem(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.menuItemById(id)}'),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return MenuItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update menu item');
    }
  }

  // ✅ ✅ ADDED 🔥 STOCK UPDATE API (NO CHANGES ELSEWHERE)
  Future<MenuItem> updateStock(String id, int stock) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.menuItems}/$id/stock'),
      headers: await _headers(),
      body: jsonEncode({'stock': stock}),
    );

    if (response.statusCode == 200) {
      return MenuItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update stock');
    }
  }

  /* =========================================================
     ORDERS
  ========================================================= */
  Future<Order> createOrder(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.orders}'),
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);

      final Map<String, dynamic> orderJson =
          decoded is Map && decoded.containsKey('order')
              ? decoded['order']
              : decoded;

      return _mapOrder(orderJson);
    } else {
      throw Exception('Failed to create order');
    }
  }

  Future<List<Order>> getUserOrders() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/my?t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final orders = data.map((e) => _mapOrder(e)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } else {
      throw Exception('Failed to load user orders');
    }
  }

  Future<List<Order>> getKitchenOrdersByCanteen(String canteenId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kitchenOrders}?canteenId=$canteenId&t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => _mapOrder(e)).toList();
    } else {
      throw Exception('Failed to load kitchen orders');
    }
  }

  /* ================= KITCHEN HISTORY ================= */
  Future<List<Order>> getKitchenHistoryByCanteen(String canteenId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/kitchen/history?canteenId=$canteenId&t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => _mapOrder(e)).toList();
    } else {
      throw Exception('Failed to load kitchen history');
    }
  }

  Future<Order> updateOrderStatus(
    String orderId,
    String status, {
    DateTime? estimatedTime,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/status'),
      headers: await _headers(),
      body: jsonEncode({
        'status': status,
        if (estimatedTime != null)
          'estimatedTime': estimatedTime.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final Map<String, dynamic> orderJson =
          decoded is Map && decoded.containsKey('order')
              ? decoded['order']
              : decoded;
      return _mapOrder(orderJson);
    } else {
      throw Exception('Failed to update order status');
    }
  }

  /* =========================================================
     ADMIN
  ========================================================= */
  Future<List<Order>> getTodayOrders() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/admin/today?t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => _mapOrder(e)).toList();
    } else {
      throw Exception('Failed to load today orders');
    }
  }

  Future<List<Order>> getTodayOrdersByCanteen(String canteenId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/admin/today?canteenId=$canteenId&t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => _mapOrder(e)).toList();
    } else {
      throw Exception('Failed to load canteen orders');
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/admin/stats?t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load admin stats');
    }
  }

  Future<Map<String, dynamic>> getAdminStatsByCanteen(String canteenId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/admin/stats?canteenId=$canteenId&t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load admin stats by canteen');
    }
  }

  /* =========================================================
     PAYMENTS
  ========================================================= */
  Future<Map<String, dynamic>> createCashfreeOrder(double amount) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/create-order'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Cashfree order creation failed');
    }
  }
}
