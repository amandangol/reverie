import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GalleryPreferencesProvider extends ChangeNotifier {
  static const String _isGridViewKey = 'gallery_is_grid_view';
  static const String _gridCrossAxisCountKey = 'gallery_grid_cross_axis_count';

  bool _isGridView = true;
  int _gridCrossAxisCount = 4;
  late SharedPreferences _prefs;

  bool get isGridView => _isGridView;
  int get gridCrossAxisCount => _gridCrossAxisCount;

  GalleryPreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _isGridView = _prefs.getBool(_isGridViewKey) ?? true;
    _gridCrossAxisCount = _prefs.getInt(_gridCrossAxisCountKey) ?? 4;
    notifyListeners();
  }

  Future<void> toggleViewMode() async {
    _isGridView = !_isGridView;
    await _prefs.setBool(_isGridViewKey, _isGridView);
    notifyListeners();
  }

  Future<void> setGridCrossAxisCount(int count) async {
    if (count != _gridCrossAxisCount) {
      _gridCrossAxisCount = count;
      await _prefs.setInt(_gridCrossAxisCountKey, count);
      notifyListeners();
    }
  }
}
