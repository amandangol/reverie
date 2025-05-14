import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/google_drive_service.dart';

class BackupProvider extends ChangeNotifier {
  final GoogleDriveService _driveService = GoogleDriveService();
  bool _isBackingUp = false;
  bool _isRestoring = false;
  double _backupProgress = 0.0;
  String? _backupError;
  final Set<AssetPathEntity> _selectedBackupAlbums = {};
  bool _mounted = true;
  String? _userEmail;
  bool _isSignedIn = false;
  static const String _signedInKey = 'google_drive_signed_in';
  static const String _userEmailKey = 'google_drive_user_email';

  // Getters
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  double get backupProgress => _backupProgress;
  String? get backupError => _backupError;
  Set<AssetPathEntity> get selectedBackupAlbums => _selectedBackupAlbums;
  String? get userEmail => _userEmail;
  bool get isSignedIn => _isSignedIn;

  BackupProvider() {
    _initializeSignInState();
  }

  Future<void> _initializeSignInState() async {
    final prefs = await SharedPreferences.getInstance();
    _isSignedIn = prefs.getBool(_signedInKey) ?? false;
    _userEmail = prefs.getString(_userEmailKey);

    if (_isSignedIn) {
      // Verify the sign-in state with Google Drive
      final isActuallySignedIn = await _driveService.isSignedIn();
      if (!isActuallySignedIn) {
        _isSignedIn = false;
        _userEmail = null;
        await prefs.remove(_signedInKey);
        await prefs.remove(_userEmailKey);
      }
    }
    notifyListeners();
  }

  Future<void> _saveSignInState(bool isSignedIn, String? email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signedInKey, isSignedIn);
    if (email != null) {
      await prefs.setString(_userEmailKey, email);
    } else {
      await prefs.remove(_userEmailKey);
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // Check Google Drive sign-in status
  Future<bool> isGoogleDriveSignedIn() async {
    final isActuallySignedIn = await _driveService.isSignedIn();
    if (isActuallySignedIn != _isSignedIn) {
      _isSignedIn = isActuallySignedIn;
      if (isActuallySignedIn) {
        _userEmail = await _driveService.getUserEmail();
        await _saveSignInState(true, _userEmail);
      } else {
        _userEmail = null;
        await _saveSignInState(false, null);
      }
      notifyListeners();
    }
    return _isSignedIn;
  }

  // Sign in to Google Drive
  Future<void> signInToGoogleDrive() async {
    try {
      await _driveService.signIn();
      _isSignedIn = true;
      _userEmail = await _driveService.getUserEmail();
      await _saveSignInState(true, _userEmail);
      notifyListeners();
    } catch (e) {
      _backupError = e.toString();
      _isSignedIn = false;
      _userEmail = null;
      await _saveSignInState(false, null);
      notifyListeners();
      rethrow;
    }
  }

  // Sign out from Google Drive
  Future<void> signOutFromGoogleDrive() async {
    try {
      await _driveService.signOut();
      _isSignedIn = false;
      _userEmail = null;
      await _saveSignInState(false, null);
      notifyListeners();
    } catch (e) {
      _backupError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Methods to manage selected albums
  void addAlbumToBackup(AssetPathEntity album) {
    _selectedBackupAlbums.add(album);
    // Only notify about album selection changes
    notifyListeners();
  }

  void removeAlbumFromBackup(AssetPathEntity album) {
    _selectedBackupAlbums.remove(album);
    // Only notify about album selection changes
    notifyListeners();
  }

  // Backup selected albums
  Future<void> backupSelectedAlbums() async {
    if (_isBackingUp || _selectedBackupAlbums.isEmpty) return;
    if (!_isSignedIn) {
      throw Exception('Please sign in to Google Drive first');
    }

    try {
      _isBackingUp = true;
      _backupProgress = 0.0;
      _backupError = null;
      notifyListeners();

      final totalAlbums = _selectedBackupAlbums.length;
      var processedAlbums = 0;

      for (final album in _selectedBackupAlbums) {
        if (!_mounted) break;

        final assets = await album.getAssetListRange(start: 0, end: 1000);
        final files = await Future.wait(
          assets.map((asset) => asset.file).where((file) => file != null),
        );

        await _driveService.backupAlbum(
          album.name,
          files.where((file) => file != null).cast<File>().toList(),
          onProgress: (progress) {
            final albumProgress = progress / totalAlbums;
            final overallProgress =
                (processedAlbums + albumProgress) / totalAlbums;
            _backupProgress = overallProgress;
            notifyListeners();
          },
        );

        processedAlbums++;
        _backupProgress = processedAlbums / totalAlbums;
        notifyListeners();
      }

      _backupProgress = 1.0;
      _selectedBackupAlbums.clear();
    } catch (e) {
      _backupError = e.toString();
      rethrow;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  // Restore from Google Drive
  Future<void> restoreFromGoogleDrive() async {
    if (_isRestoring) return;
    if (!_isSignedIn) {
      throw Exception('Please sign in to Google Drive first');
    }

    try {
      _isRestoring = true;
      _backupProgress = 0.0;
      _backupError = null;
      notifyListeners();

      final backedUpFiles = await _driveService.listBackedUpFiles();
      final totalItems = backedUpFiles.length;
      var processedItems = 0;

      for (final file in backedUpFiles) {
        if (!_mounted) break;

        final tempDir = await getTemporaryDirectory();
        final localPath = path.join(tempDir.path, file.name!);
        await _driveService.restoreFile(
          file.id!,
          localPath,
          onProgress: (progress) {
            final fileProgress = progress / totalItems;
            final overallProgress =
                (processedItems + fileProgress) / totalItems;
            _backupProgress = overallProgress;
            notifyListeners();
          },
        );

        processedItems++;
        _backupProgress = processedItems / totalItems;
        notifyListeners();
      }

      _backupProgress = 1.0;
    } catch (e) {
      _backupError = e.toString();
      rethrow;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }
}
