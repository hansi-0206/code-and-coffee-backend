import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    required this.quantity,
  });

  double get total => menuItem.price * quantity;
}

class CartProvider with ChangeNotifier {
  static const double _taxRate = 0.10;

  final List<CartItem> _items = [];

  String? _canteenId;

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.total);

  double get tax => subtotal * _taxRate;

  double get total => subtotal + tax;

  void setCanteen(String canteenId) {
    if (_canteenId != canteenId) {
      _canteenId = canteenId;
      clear();
    }
  }

  // ✅ ✅ STOCK SAFETY CHECK 🔥
  void addItem(MenuItem menuItem) {

    // 🔥 Prevent adding unavailable items
    if (menuItem.available != true || menuItem.stock == 0) {
      return;
    }

    final index =
        _items.indexWhere((item) => item.menuItem.id == menuItem.id);

    if (index >= 0) {

      // 🔥 Prevent exceeding stock
      if (_items[index].quantity >= menuItem.stock) {
        return;
      }

      _items[index].quantity++;
    } else {
      _items.add(CartItem(menuItem: menuItem, quantity: 1));
    }

    notifyListeners();
  }

  void removeItem(MenuItem menuItem) {
    final index =
        _items.indexWhere((item) => item.menuItem.id == menuItem.id);

    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void updateQuantity(MenuItem menuItem, int quantity) {
    final index =
        _items.indexWhere((item) => item.menuItem.id == menuItem.id);

    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {

        // 🔥 Clamp quantity to stock
        if (quantity > menuItem.stock) {
          quantity = menuItem.stock;
        }

        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  int getQuantity(MenuItem menuItem) {
    final index =
        _items.indexWhere((item) => item.menuItem.id == menuItem.id);
    return index >= 0 ? _items[index].quantity : 0;
  }

  // ✅ ✅ REALTIME STOCK PROTECTION 🔥🔥🔥
  /// Called when stock updates via socket
  void syncStock(MenuItem updatedItem) {

    final index =
        _items.indexWhere((item) => item.menuItem.id == updatedItem.id);

    if (index == -1) return;

    // 🔥 If stock becomes zero → remove from cart
    if (updatedItem.stock == 0 || updatedItem.available != true) {
      _items.removeAt(index);
      notifyListeners();
      return;
    }

    // 🔥 Clamp quantity if stock reduced
    if (_items[index].quantity > updatedItem.stock) {
      _items[index].quantity = updatedItem.stock;
      notifyListeners();
    }
  }

  Map<String, dynamic> buildOrderPayload({
    required String userId,
    required String userName,
    required String canteenId,
  }) {
    return {
      'userId': userId,
      'userName': userName,
      'canteenId': canteenId,
      'items': _items.map((item) => {
            'menuItem': item.menuItem.id,
            'name': item.menuItem.name,
            'price': item.menuItem.price,
            'quantity': item.quantity,
          }).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
    };
  }
}
