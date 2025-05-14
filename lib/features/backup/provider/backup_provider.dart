import 'dart:async';
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
  final Set<String> _backedUpAlbums = {};
  bool _isCancelling = false;
  String? _userName;
  String? _userPhotoUrl;

  static const String _signedInKey = 'google_drive_signed_in';
  static const String _userEmailKey = 'google_drive_user_email';
  static const String _backedUpAlbumsKey = 'backed_up_albums';

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
  Set<String> get backedUpAlbums => _backedUpAlbums;
  String? get userName => _userName;
  String? get userPhotoUrl => _userPhotoUrl;

  BackupProvider() {
    _initializeSignInState();
    _initializeBackupState();
  }

  Future<void> _initializeSignInState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSignedIn = prefs.getBool(_signedInKey) ?? false;
      _userEmail = prefs.getString(_userEmailKey);
      _userName = prefs.getString('google_drive_user_name');
      _userPhotoUrl = prefs.getString('google_drive_user_photo');

      // Always verify the actual sign-in state on initialization
      if (_isSignedIn) {
        final isActuallySignedIn = await _driveService.isSignedIn();
        if (!isActuallySignedIn) {
          // If not actually signed in, clear the stored state
          _isSignedIn = false;
          _userEmail = null;
          _userName = null;
          _userPhotoUrl = null;
          await prefs.remove(_signedInKey);
          await prefs.remove(_userEmailKey);
          await prefs.remove('google_drive_user_name');
          await prefs.remove('google_drive_user_photo');
        } else {
          // If actually signed in, ensure we have the latest user info
          final userInfo = await _driveService.getUserInfo();
          _userEmail = userInfo['email'];
          _userName = userInfo['name'];
          _userPhotoUrl = userInfo['photoUrl'];
          await _saveSignInState(true, _userEmail);
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error initializing sign-in state: $e');
      // If there's an error, assume not signed in
      _isSignedIn = false;
      _userEmail = null;
      _userName = null;
      _userPhotoUrl = null;
      notifyListeners();
    }
  }

  Future<void> _saveSignInState(bool isSignedIn, String? email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signedInKey, isSignedIn);
    if (email != null) {
      await prefs.setString(_userEmailKey, email);
      if (_userName != null) {
        await prefs.setString('google_drive_user_name', _userName!);
      }
      if (_userPhotoUrl != null) {
        await prefs.setString('google_drive_user_photo', _userPhotoUrl!);
      }
    } else {
      await prefs.remove(_userEmailKey);
      await prefs.remove('google_drive_user_name');
      await prefs.remove('google_drive_user_photo');
    }
  }

  Future<void> _initializeBackupState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _backedUpAlbums.addAll(prefs.getStringList(_backedUpAlbumsKey) ?? []);

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
        final userInfo = await _driveService.getUserInfo();
        _userEmail = userInfo['email'];
        _userName = userInfo['name'];
        _userPhotoUrl = userInfo['photoUrl'];
        await _saveSignInState(true, _userEmail);
      } else {
        _userEmail = null;
        _userName = null;
        _userPhotoUrl = null;
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
      final userInfo = await _driveService.getUserInfo();
      _userEmail = userInfo['email'];
      _userName = userInfo['name'];
      _userPhotoUrl = userInfo['photoUrl'];
      await _saveSignInState(true, _userEmail);
      notifyListeners();
    } catch (e) {
      _backupError = e.toString();
      _isSignedIn = false;
      _userEmail = null;
      _userName = null;
      _userPhotoUrl = null;
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
      _userName = null;
      _userPhotoUrl = null;
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
    notifyListeners();
  }

  void removeAlbumFromBackup(AssetPathEntity album) {
    _selectedBackupAlbums.remove(album);
    notifyListeners();
  }

  void cancelBackup() {
    if (_isBackingUp) {
      _isCancelling = true;
      _backupProgress = 0.0;
      _isBackingUp = false;
      // Create a copy of the set to avoid concurrent modification
      final albumsToClear = Set<AssetPathEntity>.from(_selectedBackupAlbums);
      _selectedBackupAlbums.clear();
      notifyListeners();
    }
  }

  Future<void> backupSelectedAlbums() async {
    if (_isBackingUp || _selectedBackupAlbums.isEmpty) return;

    // Always verify sign-in state before backup
    try {
      final isActuallySignedIn = await _driveService.isSignedIn();
      if (!isActuallySignedIn) {
        // If not signed in, clear stored state
        _isSignedIn = false;
        _userEmail = null;
        _userName = null;
        _userPhotoUrl = null;
        await _saveSignInState(false, null);
        throw Exception('Please sign in to Google Drive first');
      }

      // If signed in, update state with latest info
      _isSignedIn = true;
      final userInfo = await _driveService.getUserInfo();
      _userEmail = userInfo['email'];
      _userName = userInfo['name'];
      _userPhotoUrl = userInfo['photoUrl'];
      await _saveSignInState(true, _userEmail);
    } catch (e) {
      print('Error verifying sign-in state: $e');
      throw Exception('Please sign in to Google Drive first');
    }

    try {
      _isBackingUp = true;
      _isCancelling = false;
      _backupProgress = 0.0;
      _backupError = null;
      notifyListeners();

      // Create a copy of selected albums to avoid concurrent modification
      final albumsToProcess = Set<AssetPathEntity>.from(_selectedBackupAlbums);
      final totalAlbums = albumsToProcess.length;
      var processedAlbums = 0;

      for (final album in albumsToProcess) {
        if (!_mounted || _isCancelling) {
          _isBackingUp = false;
          _isCancelling = false;
          _backupProgress = 0.0;
          _selectedBackupAlbums.clear();
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
      if (_isCancelling) {
        _backupProgress = 0.0;
        _selectedBackupAlbums.clear();
      }
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
