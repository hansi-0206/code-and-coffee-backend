import 'package:flutter/material.dart';

import '../models/canteen.dart';
import '../services/api_service.dart';

class CanteenProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Canteen> _canteens = [];
  Canteen? _selectedCanteen;

  bool _isLoading = false;
  String? _error;

  // 🔥 ADDED — helps other providers know canteen changed
  String? _lastSelectedCanteenId;

  // ======================
  // GETTERS
  // ======================
  List<Canteen> get canteens => _canteens;
  Canteen? get selectedCanteen => _selectedCanteen;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 🔥 ADDED
  bool get hasCanteenChanged =>
      _selectedCanteen?.id != _lastSelectedCanteenId;

  // ======================
  // FETCH ALL CANTEENS
  // ======================
  Future<void> fetchCanteens() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _canteens = await _apiService.getCanteens();

      // Auto-select first canteen (optional but recommended)
      if (_canteens.isNotEmpty && _selectedCanteen == null) {
        _selectedCanteen = _canteens.first;
        _lastSelectedCanteenId = _selectedCanteen!.id;
      }
    } catch (e) {
      _error = 'Failed to load canteens';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // SELECT CANTEEN
  // ======================
  void selectCanteen(Canteen canteen) {
    // 🔥 detect change
    final bool changed = _selectedCanteen?.id != canteen.id;

    _selectedCanteen = canteen;

    if (changed) {
      _lastSelectedCanteenId = canteen.id;
    }

    notifyListeners();
  }

  // ======================
  // CLEAR STATE (LOGOUT)
  // ======================
  void clear() {
    _canteens = [];
    _selectedCanteen = null;
    _lastSelectedCanteenId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
