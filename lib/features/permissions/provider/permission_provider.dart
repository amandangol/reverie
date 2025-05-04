import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionProvider extends ChangeNotifier {
  PermissionStatus _mediaPermissionStatus = PermissionStatus.denied;
  bool _isRequestingPermission = false;

  PermissionStatus get mediaPermissionStatus => _mediaPermissionStatus;
  bool get isRequestingPermission => _isRequestingPermission;
  bool get hasMediaPermission => _mediaPermissionStatus.isGranted;

  Future<void> checkMediaPermission() async {
    final status = await Permission.photos.status;
    _mediaPermissionStatus = status;
    notifyListeners();
  }

  Future<bool> requestMediaPermission() async {
    if (_isRequestingPermission) return false;

    _isRequestingPermission = true;
    notifyListeners();

    try {
      final status = await Permission.photos.request();
      _mediaPermissionStatus = status;
      notifyListeners();
      return status.isGranted;
    } finally {
      _isRequestingPermission = false;
      notifyListeners();
    }
  }

  /// ✅ This is the correct way to open app settings
  Future<void> openSettings() async {
    await openAppSettings(); // ← from permission_handler
  }

  bool isPermanentlyDenied() {
    return _mediaPermissionStatus.isPermanentlyDenied;
  }

  bool isDenied() {
    return _mediaPermissionStatus.isDenied;
  }
}
