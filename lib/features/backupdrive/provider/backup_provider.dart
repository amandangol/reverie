import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../services/google_drive_service.dart';
import '../../../services/connectivity_service.dart';
import '../../journal/models/journal_entry.dart';
import '../../journal/providers/journal_provider.dart';

class BackupProvider extends ChangeNotifier {
  final GoogleDriveService _driveService = GoogleDriveService();
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isBackingUp = false;
  bool _isRestoring = false;
  double _backupProgress = 0.0;
  String? _backupError;
  final Set<AssetPathEntity> _selectedBackupAlbums = {};
  bool _mounted = true;
  String? _userEmail;
  bool _isSignedIn = false;
  final Map<String, Set<String>> _backedUpAlbumsPerAccount = {};
  bool _isCancelling = false;
  String? _userName;
  String? _userPhotoUrl;
  String? _lastSuccessMessage;
  String? _driveFolderUrl;
  bool _isBackingUpJournals = false;
  BuildContext? _context;

  static const String _signedInKey = 'google_drive_signed_in';
  static const String _userEmailKey = 'google_drive_user_email';
  static const String _backedUpAlbumsKey = 'backed_up_albums';

  // Add new field to track backed-up files
  final Map<String, Map<String, Set<String>>> _backedUpFilesPerAccount = {};

  // Add new field to track backed-up journals
  final Map<String, Set<String>> _backedUpJournalsPerAccount = {};

  // Getters
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  double get backupProgress => _backupProgress;
  String? get backupError => _backupError;
  Set<AssetPathEntity> get selectedBackupAlbums => _selectedBackupAlbums;
  String? get userEmail => _userEmail;
  bool get isSignedIn => _isSignedIn;
  Set<String> get backedUpAlbums => _backedUpAlbumsPerAccount[_userEmail] ?? {};
  Set<String> get backedUpJournals =>
      _backedUpJournalsPerAccount[_userEmail] ?? {};
  String? get userName => _userName;
  String? get userPhotoUrl => _userPhotoUrl;
  String? get lastSuccessMessage => _lastSuccessMessage;
  String? get driveFolderUrl => _driveFolderUrl;
  bool get isBackingUpJournals => _isBackingUpJournals;

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
      final accounts = prefs.getStringList('backup_accounts') ?? [];

      for (final account in accounts) {
        final albums = prefs.getStringList('backed_up_albums_$account') ?? [];
        _backedUpAlbumsPerAccount[account] = albums.toSet();

        // Load backed-up journals
        final journals =
            prefs.getStringList('backed_up_journals_$account') ?? [];
        _backedUpJournalsPerAccount[account] = journals.toSet();

        // Load backed-up files for each album
        _backedUpFilesPerAccount[account] = {};
        for (final albumName in albums) {
          final files =
              prefs.getStringList('backed_up_files_${account}_$albumName') ??
                  [];
          _backedUpFilesPerAccount[account]![albumName] = files.toSet();
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error initializing backup state: $e');
    }
  }

  Future<void> _saveBackedUpAlbums() async {
    if (_userEmail == null) return;

    final prefs = await SharedPreferences.getInstance();

    // Save all accounts
    final accounts = _backedUpAlbumsPerAccount.keys.toList();
    await prefs.setStringList('backup_accounts', accounts);

    // Save albums for current account
    await prefs.setStringList(
      'backed_up_albums_$_userEmail',
      _backedUpAlbumsPerAccount[_userEmail]?.toList() ?? [],
    );

    // Save journals for current account
    await prefs.setStringList(
      'backed_up_journals_$_userEmail',
      _backedUpJournalsPerAccount[_userEmail]?.toList() ?? [],
    );

    // Save backed-up files for each album
    final accountFiles = _backedUpFilesPerAccount[_userEmail] ?? {};
    for (final entry in accountFiles.entries) {
      await prefs.setStringList(
        'backed_up_files_${_userEmail}_${entry.key}',
        entry.value.toList(),
      );
    }
  }

  bool isAlbumBackedUp(AssetPathEntity album) {
    if (_userEmail == null) return false;
    return _backedUpAlbumsPerAccount[_userEmail]?.contains(album.name) ?? false;
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
    if (!await _connectivityService.checkConnection()) {
      throw NoInternetException();
    }

    try {
      await _driveService.signIn();
      _isSignedIn = true;
      final userInfo = await _driveService.getUserInfo();
      _userEmail = userInfo['email'];
      _userName = userInfo['name'];
      _userPhotoUrl = userInfo['photoUrl'];
      await _saveSignInState(true, _userEmail);
      _lastSuccessMessage = 'Successfully signed in to Google Drive';

      // Get the Drive folder URL after signing in
      await getDriveFolderUrl();

      notifyListeners();
    } catch (e) {
      _backupError = e.toString();
      _isSignedIn = false;
      _userEmail = null;
      _userName = null;
      _userPhotoUrl = null;
      _driveFolderUrl = null;
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
    if (_userEmail == null) {
      throw Exception('Please sign in to Google Drive first');
    }

    if (!await _connectivityService.checkConnection()) {
      throw NoInternetException();
    }

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
            // Initialize sets if they don't exist
            _backedUpAlbumsPerAccount[_userEmail!] ??= {};
            _backedUpFilesPerAccount[_userEmail!] ??= {};

            _backedUpAlbumsPerAccount[_userEmail]!.add(album.name);
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
        _lastSuccessMessage =
            'Successfully backed up ${totalAlbums} ${totalAlbums == 1 ? 'album' : 'albums'}';
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
    if (!await _connectivityService.checkConnection()) {
      throw NoInternetException();
    }
    if (_context == null) {
      throw Exception('Context not set');
    }

    try {
      _isRestoring = true;
      _backupProgress = 0.0;
      _backupError = null;
      notifyListeners();

      final backedUpFiles = await _driveService.listBackedUpFiles();
      print('[DEBUG] Total files found: ${backedUpFiles.length}');
      final totalItems = backedUpFiles.length;
      var processedItems = 0;

      // Create a temporary directory for restored files
      final tempDir = await getTemporaryDirectory();
      final restoredJournals = <JournalEntry>[];

      for (final file in backedUpFiles) {
        if (!_mounted) break;

        print('[DEBUG] Processing file: ${file.name}');
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

        // If it's a journal entry file, parse and add it to the list
        if ((file.name!.startsWith('journals/') ||
                file.name!.endsWith('.json')) &&
            file.name!.endsWith('.json')) {
          print('[DEBUG] Found journal file: ${file.name}');
          try {
            final jsonString = await File(localPath).readAsString();
            print('[DEBUG] Journal file content: $jsonString');
            final jsonData = json.decode(jsonString);
            final journalEntry = JournalEntry.fromJson(jsonData);
            restoredJournals.add(journalEntry);
            print(
                '[DEBUG] Successfully parsed journal entry: ${journalEntry.id}');
          } catch (e) {
            print('[DEBUG] Error parsing journal entry: $e');
          }
        }

        processedItems++;
        _backupProgress = processedItems / totalItems;
        notifyListeners();
      }

      // Save restored journal entries
      if (restoredJournals.isNotEmpty) {
        final journalProvider =
            Provider.of<JournalProvider>(_context!, listen: false);
        print('[DEBUG] Initializing JournalProvider...');
        await journalProvider.initialize(); // Ensure DB is ready
        print('[DEBUG] Clearing all journal entries...');
        await journalProvider.clearAll();
        print(
            '[DEBUG] Adding restored journal entries: count = \'${restoredJournals.length}\'');
        int successCount = 0;
        for (final entry in restoredJournals) {
          final result = await journalProvider.addEntry(entry);
          print('[DEBUG] addEntry for id=${entry.id} returned $result');
          if (result) successCount++;
        }
        print('[DEBUG] Total successfully added: $successCount');
        print('[DEBUG] Reloading entries...');
        await journalProvider.loadEntries();
        print(
            '[DEBUG] Entries after reload: ${journalProvider.entries.length}');
        _backedUpJournalsPerAccount[_userEmail!] =
            restoredJournals.map((e) => e.id).toSet();
        await _saveBackedUpAlbums();
        // Force UI update
        journalProvider.notifyListeners();
      } else {
        print('[DEBUG] No journal entries found to restore.');
      }

      _backupProgress = 1.0;
      _lastSuccessMessage =
          'Successfully restored ${restoredJournals.length} journal entries';
    } catch (e) {
      _backupError = e.toString();
      rethrow;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  // Clear success message
  void clearSuccessMessage() {
    _lastSuccessMessage = null;
    notifyListeners();
  }

  //  restore UI method
  Future<void> showRestoreDialog(BuildContext context) async {
    if (!_isSignedIn) {
      throw Exception('Please sign in to Google Drive first');
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will restore all your backed up albums from Google Drive. '
          'Any existing files with the same names will be overwritten. '
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await restoreFromGoogleDrive();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully restored from backup'),
              backgroundColor: Color(0xFF34A853),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error restoring backup: ${e.toString()}'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  //   method to get the Drive folder URL
  Future<String?> getDriveFolderUrl() async {
    if (!_isSignedIn) {
      print('Not signed in, cannot get Drive folder URL');
      return null;
    }
    try {
      print('Fetching Drive folder URL...');
      _driveFolderUrl = await _driveService.getBackupFolderUrl();
      print('Drive folder URL: $_driveFolderUrl');
      notifyListeners();
      return _driveFolderUrl;
    } catch (e) {
      print('Error getting Drive folder URL: $e');
      return null;
    }
  }

  //   method for backing up journals
  Future<void> backupJournals(List<JournalEntry> journals) async {
    if (_isBackingUpJournals || journals.isEmpty) return;
    if (_userEmail == null) {
      throw Exception('Please sign in to Google Drive first');
    }

    if (!await _connectivityService.checkConnection()) {
      throw NoInternetException();
    }

    try {
      _isBackingUpJournals = true;
      _backupProgress = 0.0;
      _backupError = null;
      notifyListeners();

      // Filter out already backed up journals
      final journalsToBackup =
          journals.where((journal) => !isJournalBackedUp(journal.id)).toList();

      final totalJournals = journalsToBackup.length;
      var processedJournals = 0;

      for (final journal in journalsToBackup) {
        if (!_mounted || _isCancelling) {
          _isBackingUpJournals = false;
          _isCancelling = false;
          _backupProgress = 0.0;
          notifyListeners();
          return;
        }

        // Create a JSON file for the journal entry
        final journalData = {
          'id': journal.id,
          'title': journal.title,
          'content': journal.content,
          'date': journal.date.toIso8601String(),
          'mediaIds': journal.mediaIds,
          'mood': journal.mood,
          'tags': journal.tags,
          'lastEdited': journal.lastEdited?.toIso8601String(),
        };

        final jsonString = json.encode(journalData);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${journal.id}.json');
        await tempFile.writeAsString(jsonString);

        // Upload to Google Drive
        await _driveService.uploadFile(
          tempFile,
          'journals/${journal.id}.json',
          onProgress: (progress) {
            if (!_isCancelling) {
              final journalProgress = progress / totalJournals;
              final overallProgress =
                  (processedJournals + journalProgress) / totalJournals;
              _backupProgress = overallProgress;
              notifyListeners();
            }
          },
        );

        // Clean up temp file
        await tempFile.delete();

        if (!_isCancelling) {
          // Initialize sets if they don't exist
          _backedUpJournalsPerAccount[_userEmail!] ??= {};
          _backedUpJournalsPerAccount[_userEmail]!.add(journal.id);
          await _saveBackedUpAlbums();
        }

        processedJournals++;
        _backupProgress = processedJournals / totalJournals;
        notifyListeners();
      }

      if (!_isCancelling) {
        _backupProgress = 1.0;
        _lastSuccessMessage =
            'Successfully backed up $processedJournals journal entries';
      }
    } catch (e) {
      _backupError = e.toString();
      rethrow;
    } finally {
      _isBackingUpJournals = false;
      _isCancelling = false;
      if (_isCancelling) {
        _backupProgress = 0.0;
      }
      notifyListeners();
    }
  }

  // Add method to check if a journal is backed up
  bool isJournalBackedUp(String journalId) {
    if (_userEmail == null) return false;
    return _backedUpJournalsPerAccount[_userEmail]?.contains(journalId) ??
        false;
  }

  void setContext(BuildContext context) {
    _context = context;
  }
}
