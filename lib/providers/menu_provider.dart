import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/menu_item.dart';
import '../services/api_service.dart';

class MenuProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<MenuItem> _items = [];
  bool _isLoading = false;
  String? _error;

  String? _currentCanteenId;

  late IO.Socket socket;

  MenuProvider() {
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(
      "https://code-and-coffee-backend.onrender.com",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print("✅ Socket Connected");
    });

    socket.on("stockUpdated", (data) {
      final menuItemId = data['menuItemId'];
      final newStock = data['newStock'];

      _updateStockRealtime(menuItemId, newStock);
    });

    socket.onDisconnect((_) {
      print("❌ Socket Disconnected");
    });
  }

  // ✅ ✅ FIXED REALTIME STOCK HANDLER 🔥🔥🔥
  void _updateStockRealtime(String menuItemId, int newStock) {
    final index = _items.indexWhere((item) => item.id == menuItemId);

    if (index != -1) {
      final item = _items[index];

      _items[index] = MenuItem(
        id: item.id,
        name: item.name,
        category: item.category,
        price: item.price,
        description: item.description,
        image: item.image,

        // ✅ CRITICAL FIXES 🔥
        available: newStock > 0,
        stock: newStock,
      );

      notifyListeners();
    }
  }

  List<MenuItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMenuItemsByCanteen(String canteenId) async {
    if (_currentCanteenId != canteenId) {
      _items = [];
      _currentCanteenId = canteenId;
      notifyListeners();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _apiService.getMenuItemsByCanteen(canteenId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMenuItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _apiService.getMenuItems();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMenuItem(Map<String, dynamic> data) async {
    try {
      final newItem = await _apiService.createMenuItem(data);
      _items.add(newItem);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final updatedItem = await _apiService.updateMenuItem(id, data);
      final index = _items.indexWhere((item) => item.id == id);

      if (index >= 0) {
        _items[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStock(String id, int stock) async {
    try {
      print("Updating stock for $id to $stock");

      final updatedItem = await _apiService.updateStock(id, stock);

      print("Backend returned stock: ${updatedItem.stock}");

      final index = _items.indexWhere((item) => item.id == id);

      print("Index found: $index");

      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();
        print("Stock updated locally");
      }
    } catch (e) {
      print("Stock update error: $e");
      _error = e.toString();
      notifyListeners();
  }
}
  List<MenuItem> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  List<String> get categories =>
      _items.map((item) => item.category).toSet().toList();

  void clear() {
    _items = [];
    _currentCanteenId = null;
    _isLoading = false;
    _error = null;

    socket.disconnect();

    notifyListeners();
  }
}
