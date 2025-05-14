import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  final Set<String> _backedUpAlbums = {};
  bool _isAutoBackupEnabled = false;
  StreamSubscription? _connectivitySubscription;
  bool _isWifiConnected = false;
  bool _isCancelling = false;

  static const String _signedInKey = 'google_drive_signed_in';
  static const String _userEmailKey = 'google_drive_user_email';
  static const String _backedUpAlbumsKey = 'backed_up_albums';
  static const String _autoBackupKey = 'auto_backup_enabled';

  // Add new field to track backed-up files
  final Map<String, Set<String>> _backedUpFiles = {};

  // Getters
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  double get backupProgress => _backupProgress;
  String? get backupError => _backupError;
  Set<AssetPathEntity> get selectedBackupAlbums => _selectedBackupAlbums;
  String? get userEmail => _userEmail;
  bool get isSignedIn => _isSignedIn;
  bool get isAutoBackupEnabled => _isAutoBackupEnabled;
  Set<String> get backedUpAlbums => _backedUpAlbums;
  bool get isWifiConnected => _isWifiConnected;

  BackupProvider() {
    _initializeSignInState();
    _initializeBackupState();
    _initializeConnectivity();
  }

  Future<void> _initializeConnectivity() async {
    try {
      // Check initial connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _isWifiConnected = connectivityResult == ConnectivityResult.wifi;
      notifyListeners();

      // Listen for connectivity changes
      _connectivitySubscription =
          Connectivity().onConnectivityChanged.listen((result) {
        _isWifiConnected = result == ConnectivityResult.wifi;
        notifyListeners();

        if (_isWifiConnected && _isAutoBackupEnabled && _isSignedIn) {
          _autoBackupAlbums();
        }
      });
    } catch (e) {
      print('Error initializing connectivity: $e');
      // Don't throw the error, just log it and continue without auto-backup
      _isWifiConnected = false;
    }
  }

  Future<void> _initializeSignInState() async {
    final prefs = await SharedPreferences.getInstance();
    _isSignedIn = prefs.getBool(_signedInKey) ?? false;
    _userEmail = prefs.getString(_userEmailKey);

    if (_isSignedIn) {
      // Only verify sign-in state if we don't have an email
      if (_userEmail == null) {
        final isActuallySignedIn = await _driveService.isSignedIn();
        if (!isActuallySignedIn) {
          _isSignedIn = false;
          _userEmail = null;
          await prefs.remove(_signedInKey);
          await prefs.remove(_userEmailKey);
        } else {
          _userEmail = await _driveService.getUserEmail();
          await _saveSignInState(true, _userEmail);
        }
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

  Future<void> _initializeBackupState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backedUpAlbums.addAll(prefs.getStringList(_backedUpAlbumsKey) ?? []);
      _isAutoBackupEnabled = prefs.getBool(_autoBackupKey) ?? false;

      // Load backed-up files for each album
      for (final albumName in _backedUpAlbums) {
        final files = prefs.getStringList('backed_up_files_$albumName') ?? [];
        _backedUpFiles[albumName] = files.toSet();
      }

      notifyListeners();
    } catch (e) {
      print('Error initializing backup state: $e');
    }
  }

  Future<void> _autoBackupAlbums() async {
    if (_isBackingUp || _selectedBackupAlbums.isEmpty) return;
    try {
      await backupSelectedAlbums();
    } catch (e) {
      print('Error during auto-backup: $e');
      // Don't throw the error, just log it
    }
  }

  Future<void> toggleAutoBackup(bool enabled) async {
    _isAutoBackupEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoBackupKey, enabled);
      notifyListeners();

      // If enabling auto-backup and we're on WiFi, trigger a backup
      if (enabled && _isWifiConnected && _isSignedIn) {
        _autoBackupAlbums();
      }
    } catch (e) {
      print('Error toggling auto-backup: $e');
      // Revert the change if saving failed
      _isAutoBackupEnabled = !enabled;
      notifyListeners();
    }
  }

  Future<void> _saveBackedUpAlbums() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_backedUpAlbumsKey, _backedUpAlbums.toList());

    // Save backed-up files for each album
    for (final entry in _backedUpFiles.entries) {
      await prefs.setStringList(
          'backed_up_files_${entry.key}', entry.value.toList());
    }
  }

  bool isAlbumBackedUp(AssetPathEntity album) {
    return _backedUpAlbums.contains(album.name);
  }

  @override
  void dispose() {
    _mounted = false;
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // Check Google Drive sign-in status
  Future<bool> isGoogleDriveSignedIn() async {
    if (_isSignedIn && _userEmail != null) {
      return true;
    }

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

  // Update cancelBackup method
  void cancelBackup() {
    if (_isBackingUp) {
      _isCancelling = true;
      _backupProgress = 0.0;
      notifyListeners();
    }
  }

  // Update backupSelectedAlbums method
  Future<void> backupSelectedAlbums() async {
    if (_isBackingUp || _selectedBackupAlbums.isEmpty) return;
    if (!_isSignedIn) {
      throw Exception('Please sign in to Google Drive first');
    }

    try {
      _isBackingUp = true;
      _isCancelling = false;
      _backupProgress = 0.0;
      _backupError = null;
      notifyListeners();

      final totalAlbums = _selectedBackupAlbums.length;
      var processedAlbums = 0;

      for (final album in _selectedBackupAlbums) {
        if (!_mounted || _isCancelling) {
          _isBackingUp = false;
          _isCancelling = false;
          notifyListeners();
          return;
        }

        final assets = await album.getAssetListRange(start: 0, end: 1000);
        final files = await Future.wait(
          assets.map((asset) => asset.file).where((file) => file != null),
        );

        if (files.isNotEmpty) {
          await _driveService.backupAlbum(
            album.name,
            files.cast<File>(),
            onProgress: (progress) {
              if (!_isCancelling) {
                final albumProgress = progress / totalAlbums;
                final overallProgress =
                    (processedAlbums + albumProgress) / totalAlbums;
                _backupProgress = overallProgress;
                notifyListeners();
              }
            },
          );

          if (!_isCancelling) {
            _backedUpAlbums.add(album.name);
            await _saveBackedUpAlbums();
          }
        }

        processedAlbums++;
        _backupProgress = processedAlbums / totalAlbums;
        notifyListeners();
      }

      if (!_isCancelling) {
        _backupProgress = 1.0;
        _selectedBackupAlbums.clear();
      }
    } catch (e) {
      _backupError = e.toString();
      rethrow;
    } finally {
      _isBackingUp = false;
      _isCancelling = false;
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
