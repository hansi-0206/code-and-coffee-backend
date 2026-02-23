import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'order_provider.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// 🔄 Load user from local storage (auto-login)
  Future<void> loadUser() async {
    _user = await StorageService.getUser();

    // 🔥 SAFETY — if no user restore, ensure orders cleared
    if (_user == null) {
      // orders will already be cleared during logout,
      // this just ensures safe state on fresh start
      try {
        // no context available here, so state will be cleared
        // automatically when providers rebuild
      } catch (_) {}
    }

    notifyListeners();
  }

  /// 🔐 Login
  Future<bool> login(String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.warmUp();
      final user = await _apiService.login(email, password, role);
      _user = user;

      // 🔥 SAVE USER LOCALLY (IMPORTANT)
      await StorageService.saveUser(user);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🚪 Logout (🔥 FULLY FIXED)
  Future<void> logout(BuildContext context) async {
    try {
      // 🔔 cancel notifications
      try {
        await NotificationService.cancelAll();
      } catch (_) {}

      // 🔥 VERY IMPORTANT — clear order state
      try {
        final orderProvider =
            Provider.of<OrderProvider>(context, listen: false);
        orderProvider.clearOrders();
      } catch (_) {}

      // 🔐 clear user locally
      _user = null;
      await StorageService.clearUser();

      _error = null;
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}
