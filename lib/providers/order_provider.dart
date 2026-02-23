import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Order> _activeOrders = [];
  List<Order> _orderHistory = [];
  List<Order> _todayOrders = [];
  List<Order> _kitchenHistory = [];

  final Map<String, String> _previousStatuses = {};

  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;

  bool _hasLoadedOrders = false;

  int _todayOrdersCount = 0;
  double _totalRevenue = 0;

  /* ================= GETTERS ================= */

  List<Order> get activeOrders => List.unmodifiable(_activeOrders);
  List<Order> get orderHistory => List.unmodifiable(_orderHistory);
  List<Order> get todayOrders => List.unmodifiable(_todayOrders);
  List<Order> get kitchenHistory => List.unmodifiable(_kitchenHistory);

  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoadedOrders => _hasLoadedOrders;

  int get todayOrdersCount => _todayOrdersCount;
  double get totalRevenue => _totalRevenue;

  bool get hasActiveOrder =>
      _activeOrders.any((o) =>
          o.status == OrderStatus.pending ||
          o.status == OrderStatus.preparing ||
          o.status == OrderStatus.ready);

  /* ================= CANTEEN FILTERED ================= */

  List<Order> activeOrdersByCanteen(String canteenId) =>
      _activeOrders.where((o) => o.canteenId == canteenId).toList();

  List<Order> orderHistoryByCanteen(String canteenId) =>
      _orderHistory.where((o) => o.canteenId == canteenId).toList();

  Order? currentOrderByCanteen(String canteenId) {
    try {
      return _activeOrders.firstWhere((o) => o.canteenId == canteenId);
    } catch (_) {
      return null;
    }
  }

  /* ================= RESTORE ================= */

  Future<void> restoreActiveOrder() async {
    await loadUserOrders();
  }

  /* ================= CLEAR ================= */

  void clearOrders() {
    _activeOrders.clear();
    _orderHistory.clear();
    _todayOrders.clear();
    _kitchenHistory.clear();
    _previousStatuses.clear();
    _currentOrder = null;
    _todayOrdersCount = 0;
    _totalRevenue = 0;
    _error = null;
    _isLoading = false;
    _hasLoadedOrders = false;
    notifyListeners();
  }

  /* ================= CREATE ORDER ================= */

  Future<void> createOrder(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      data['status'] ??= OrderStatus.pending;
      final createdOrder = await _apiService.createOrder(data);

      await loadUserOrders();

      _currentOrder =
          _activeOrders.firstWhere((o) => o.id == createdOrder.id,
              orElse: () =>
                  _activeOrders.isNotEmpty ? _activeOrders.first : createdOrder);

      _previousStatuses[createdOrder.id] = createdOrder.status;
    } catch (e) {

      final errorString = e.toString();

      if (errorString.contains("OUT_OF_STOCK") ||
          errorString.contains("stock") ||
          errorString.contains("availability")) {
        _error = "Some items just went out of stock ❌";
      } else {
        _error = errorString;
      }
}
  }

  /* ================= LOAD USER ORDERS ================= */

  Future<void> loadUserOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final orders = await _apiService.getUserOrders();

      _activeOrders = orders.where((o) =>
          o.status == OrderStatus.pending ||
          o.status == OrderStatus.preparing ||
          o.status == OrderStatus.ready).toList();

      _orderHistory =
          orders.where((o) => o.status == OrderStatus.completed).toList();

      _currentOrder =
          _activeOrders.isNotEmpty ? _activeOrders.first : null;

      _hasLoadedOrders = true;

      await _checkStatusChanges(orders);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /* ================= COMPLETE ORDER ================= */

  Future<void> completeOrder(String orderId) async {
    try {
      final index = _activeOrders.indexWhere((o) => o.id == orderId);

      if (index != -1) {
        final existing = _activeOrders.removeAt(index);
        final completedOrder =
            existing.copyWith(status: OrderStatus.completed);
        _orderHistory.insert(0, completedOrder);
        _currentOrder = null;
      }

      await updateOrderStatus(orderId, OrderStatus.completed);
      await loadUserOrders();
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /* ================= KITCHEN ================= */

  Future<void> loadKitchenOrdersByCanteen(String canteenId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final active =
          await _apiService.getKitchenOrdersByCanteen(canteenId);
      final history =
          await _apiService.getKitchenHistoryByCanteen(canteenId);

      _activeOrders = active;
      _kitchenHistory = history;

      if (_currentOrder != null &&
          !_activeOrders.any((o) => o.id == _currentOrder!.id)) {
        _currentOrder = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /* ================= UPDATE STATUS ================= */

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    DateTime? estimatedTime,
  }) async {
    try {
      final updated = await _apiService.updateOrderStatus(
        orderId,
        status,
        estimatedTime: estimatedTime,
      );

      _activeOrders.removeWhere((o) => o.id == orderId);

      if (updated.status == OrderStatus.pending ||
          updated.status == OrderStatus.preparing ||
          updated.status == OrderStatus.ready) {
        _activeOrders.insert(0, updated);
        _currentOrder = updated;
      } else {
        _orderHistory.insert(0, updated);
        _currentOrder = null;
      }

      await loadUserOrders();

      if (estimatedTime != null) {
        await NotificationService.show(
          title: 'Order Time Updated ⏱️',
          body: 'Kitchen has updated your order time',
        );
      }

      _previousStatuses[updated.id] = updated.status;
      await _showStatusNotification(updated.status);
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /* ================= ADMIN ================= */

  Future<void> loadTodayOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final orders = await _apiService.getTodayOrders();
      _applyAdminOrderStats(orders);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayOrdersByCanteen(String canteenId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final orders =
          await _apiService.getTodayOrdersByCanteen(canteenId);
      _applyAdminOrderStats(orders);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminStats() async {
    final res = await _apiService.getAdminStats();
    _todayOrdersCount = res['todayOrders'] ?? 0;
    _totalRevenue = (res['totalRevenue'] ?? 0).toDouble();
    notifyListeners();
  }

  Future<void> fetchAdminStatsByCanteen(String canteenId) async {
    final res =
        await _apiService.getAdminStatsByCanteen(canteenId);
    _todayOrdersCount = res['todayOrders'] ?? 0;
    _totalRevenue = (res['totalRevenue'] ?? 0).toDouble();
    notifyListeners();
  }

  /* ================= HELPERS ================= */

  void _applyAdminOrderStats(List<Order> orders) {
    _todayOrders = orders;
    _todayOrdersCount = orders.length;
    _totalRevenue =
        orders.fold(0.0, (sum, o) => sum + o.total);
  }

  Future<void> _checkStatusChanges(List<Order> orders) async {
    for (final o in orders) {
      if (_previousStatuses.containsKey(o.id) &&
          _previousStatuses[o.id] != o.status) {
        await _showStatusNotification(o.status);
      }
      _previousStatuses[o.id] = o.status;
    }
  }

  Future<void> _showStatusNotification(String status) async {
    switch (status) {
      case OrderStatus.pending:
        await NotificationService.show(
          title: '🧾 Order Placed',
          body: 'Your order has been placed successfully!',
        );
        break;
      case OrderStatus.preparing:
        await NotificationService.show(
          title: '👨‍🍳 Preparing',
          body: 'Your order is being prepared',
        );
        break;
      case OrderStatus.ready:
        await NotificationService.show(
          title: '🔔 Ready',
          body: 'Your order is ready for pickup!',
        );
        break;
      case OrderStatus.completed:
        await NotificationService.show(
          title: '✅ Completed',
          body: 'Thank you for your order!',
        );
        break;
    }
  }

  /* ================= FILTERS ================= */

  List<Order> get newOrders =>
      _activeOrders.where((o) => o.status == OrderStatus.pending).toList();

  List<Order> get preparingOrders =>
      _activeOrders.where((o) => o.status == OrderStatus.preparing).toList();

  List<Order> get readyOrders =>
      _activeOrders.where((o) => o.status == OrderStatus.ready).toList();

  /* ===== padding ===== */
  void _pad1() {}
  void _pad2() {}
  void _pad3() {}
  void _pad4() {}
  void _pad5() {}
}
