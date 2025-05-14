import 'dart:async';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveService {
  static const String _appFolderName = 'ReverieBackup';
  static const String _credentialsKey = 'google_drive_credentials';
  static const String _accessTokenKey = 'google_drive_access_token';
  static const String _refreshTokenKey = 'google_drive_refresh_token';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
    signInOption: SignInOption.standard,
  );

  drive.DriveApi? _driveApi;
  String? _folderId;
  String? _userEmail;
  String? _accessToken;
  String? _refreshToken;

  Future<bool> isSignedIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        // Try to restore from saved tokens
        final prefs = await SharedPreferences.getInstance();
        _accessToken = prefs.getString(_accessTokenKey);
        _refreshToken = prefs.getString(_refreshTokenKey);

        if (_accessToken != null) {
          try {
            final client = GoogleAuthClient(_accessToken!);
            _driveApi = drive.DriveApi(client);
            _folderId = await _getOrCreateAppFolder();
            return true;
          } catch (e) {
            // Token is invalid, clear it
            await prefs.remove(_accessTokenKey);
            await prefs.remove(_refreshTokenKey);
            _accessToken = null;
            _refreshToken = null;
            return false;
          }
        }
        return false;
      }

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        return false;
      }

      _accessToken = auth.accessToken;
      _refreshToken = auth.idToken;

      // Save tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, _accessToken!);
      if (_refreshToken != null) {
        await prefs.setString(_refreshTokenKey, _refreshToken!);
      }

      final client = GoogleAuthClient(_accessToken!);
      _driveApi = drive.DriveApi(client);
      _folderId = await _getOrCreateAppFolder();
      _userEmail = account.email;
      return true;
    } catch (e) {
      print('Error checking sign-in status: $e');
      return false;
    }
  }

  Future<String?> getUserEmail() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _userEmail = account.email;
        return _userEmail;
      }
      return _userEmail;
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }

  Future<void> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Sign in aborted');
      }

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        throw Exception('Failed to get access token');
      }

      _accessToken = auth.accessToken;
      _refreshToken = auth.idToken;

      // Save tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, _accessToken!);
      if (_refreshToken != null) {
        await prefs.setString(_refreshTokenKey, _refreshToken!);
      }

      final client = GoogleAuthClient(_accessToken!);
      _driveApi = drive.DriveApi(client);
      _folderId = await _getOrCreateAppFolder();
      _userEmail = account.email;
    } catch (e) {
      _driveApi = null;
      _folderId = null;
      _userEmail = null;
      _accessToken = null;
      _refreshToken = null;

      // Clear saved tokens on error
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_accessTokenKey);
        await prefs.remove(_refreshTokenKey);
      } catch (_) {
        // Ignore errors during cleanup
      }

      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      // Clear saved tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);

      _driveApi = null;
      _folderId = null;
      _userEmail = null;
      _accessToken = null;
      _refreshToken = null;
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<String?> _getOrCreateAppFolder() async {
    if (_driveApi == null) return null;

    try {
      // Search for existing folder in root
      final result = await _driveApi!.files.list(
        q: "name = '$_appFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
      );

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }

      // Create new folder if not found
      final folder = drive.File()
        ..name = _appFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi!.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      print('Error getting/creating app folder: $e');
      rethrow;
    }
  }

  Future<void> backupFile(File file, String fileName,
      {Function(double)? onProgress}) async {
    if (_driveApi == null || _folderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final fileStream = file.openRead();
      final fileSize = await file.length();
      var uploadedBytes = 0;

      // Create a stream transformer to track upload progress
      final progressStream = fileStream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            uploadedBytes += data.length;
            if (onProgress != null) {
              onProgress(uploadedBytes / fileSize);
            }
            sink.add(data);
          },
        ),
      );

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_folderId!];

      await _driveApi!.files.create(
        driveFile,
        uploadMedia: drive.Media(progressStream, fileSize),
      );
    } catch (e) {
      print('Error backing up file: $e');
      rethrow;
    }
  }

  Future<List<drive.File>> listBackedUpFiles() async {
    if (_driveApi == null || _folderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final result = await _driveApi!.files.list(
        q: "'$_folderId' in parents and trashed = false",
        spaces: 'drive',
      );

      // Filter and map the files to include only the fields we need
      return result.files
              ?.map((file) => drive.File()
                ..id = file.id
                ..name = file.name
                ..size = file.size
                ..createdTime = file.createdTime)
              .toList() ??
          [];
    } catch (e) {
      print('Error listing backed up files: $e');
      rethrow;
    }
  }

  Future<void> restoreFile(String fileId, String localPath,
      {Function(double)? onProgress}) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as http.Response;

      final file = File(localPath);
      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      final sink = file.openWrite();
      final bytes = response.bodyBytes;

      // Process chunks of data
      const chunkSize = 8192; // 8KB chunks
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end =
            (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.close();
    } catch (e) {
      print('Error restoring file: $e');
      rethrow;
    }
  }

  // Add method to backup a specific album
  Future<void> backupAlbum(String albumName, List<File> files,
      {Function(double)? onProgress}) async {
    if (_driveApi == null || _folderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      // Get or create album folder
      String? albumFolderId;
      final result = await _driveApi!.files.list(
        q: "name = '$albumName' and mimeType = 'application/vnd.google-apps.folder' and '$_folderId' in parents and trashed = false",
        spaces: 'drive',
      );

      if (result.files != null && result.files!.isNotEmpty) {
        albumFolderId = result.files!.first.id;
      } else {
        final albumFolder = drive.File()
          ..name = albumName
          ..mimeType = 'application/vnd.google-apps.folder'
          ..parents = [_folderId!];

        final createdFolder = await _driveApi!.files.create(albumFolder);
        albumFolderId = createdFolder.id;
      }

      // Get list of existing files in the album
      final existingFiles = await _driveApi!.files.list(
        q: "'$albumFolderId' in parents and trashed = false",
        spaces: 'drive',
      );

      final existingFileNames =
          existingFiles.files?.map((file) => file.name).toSet() ?? {};

      final totalFiles = files.length;
      var processedFiles = 0;

      for (final file in files) {
        if (onProgress != null) {
          onProgress(processedFiles / totalFiles);
        }

        final fileName = path.basename(file.path);

        // Skip if file already exists
        if (existingFileNames.contains(fileName)) {
          processedFiles++;
          continue;
        }

        // Create file in the album folder
        final driveFile = drive.File()
          ..name = fileName
          ..parents = [albumFolderId!];

        final fileStream = file.openRead();
        final fileSize = await file.length();
        var uploadedBytes = 0;

        // Create a stream transformer to track upload progress
        final progressStream = fileStream.transform(
          StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (data, sink) {
              uploadedBytes += data.length;
              if (onProgress != null) {
                final fileProgress = uploadedBytes / fileSize;
                final overallProgress =
                    (processedFiles + fileProgress) / totalFiles;
                onProgress(overallProgress);
              }
              sink.add(data);
            },
          ),
        );

        await _driveApi!.files.create(
          driveFile,
          uploadMedia: drive.Media(progressStream, fileSize),
        );

        processedFiles++;
      }
    } catch (e) {
      print('Error backing up album: $e');
      rethrow;
    }
  }

  // Add method to list backed up albums
  Future<List<drive.File>> listBackedUpAlbums() async {
    if (_driveApi == null || _folderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final result = await _driveApi!.files.list(
        q: "'$_folderId' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
      );

      return result.files ?? [];
    } catch (e) {
      print('Error listing backed up albums: $e');
      rethrow;
    }
  }

  // Add method to list files in a backed up album
  Future<List<drive.File>> listFilesInAlbum(String albumId) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final result = await _driveApi!.files.list(
        q: "'$albumId' in parents and trashed = false",
        spaces: 'drive',
      );

      return result.files ?? [];
    } catch (e) {
      print('Error listing files in album: $e');
      rethrow;
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}
