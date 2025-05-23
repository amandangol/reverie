import 'dart:async';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveService {
  static const String _appFolderName = 'ReverieBackup';
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
  bool _isSignedIn = false;

  Future<bool> isSignedIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        _isSignedIn = false;
        return false;
      }

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        _isSignedIn = false;
        return false;
      }

      final client = GoogleAuthClient(auth.accessToken!);
      _driveApi = drive.DriveApi(client);
      _folderId = await _getOrCreateAppFolder();
      _isSignedIn = true;
      return true;
    } catch (e) {
      _isSignedIn = false;
      _driveApi = null;
      _folderId = null;
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
        throw Exception('Sign in was cancelled');
      }

      final auth = await account.authentication;
      final client = GoogleAuthClient(auth.accessToken!);
      _driveApi = drive.DriveApi(client);
      _isSignedIn = true;

      // Create or get backup folder
      _folderId = await _getOrCreateAppFolder();
    } catch (e) {
      _isSignedIn = false;
      _driveApi = null;
      _folderId = null;
      rethrow;
    }
  }

  Future<void> signOut() async {
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
    _isSignedIn = false;
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
      print('[DEBUG] Listing files in folder: $_folderId');
      final result = await _driveApi!.files.list(
        q: "'$_folderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id,name,size,createdTime,mimeType)',
      );

      print('[DEBUG] Found ${result.files?.length ?? 0} files');

      // Filter out Google Docs files and map the remaining files
      final files = result.files
              ?.where((file) =>
                  !(file.mimeType?.startsWith('application/vnd.google-apps.') ??
                      false))
              .map((file) => drive.File()
                ..id = file.id
                ..name = file.name
                ..size = file.size
                ..createdTime = file.createdTime)
              .toList() ??
          [];

      print('[DEBUG] After filtering, ${files.length} files remain');
      for (final file in files) {
        print('[DEBUG] File: ${file.name}');
      }

      return files;
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
      // First get the file metadata to check its type
      final fileMetadata = await _driveApi!.files.get(
        fileId,
        $fields: 'id,name,mimeType,size',
      ) as drive.File;

      // Check if it's a Google Docs/Sheets/Slides file
      if (fileMetadata.mimeType?.startsWith('application/vnd.google-apps.') ??
          false) {
        // Skip Google Docs files as they can't be directly downloaded
        print('Skipping Google Docs file: ${fileMetadata.name}');
        return;
      }

      // For regular files, proceed with download
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      final localFile = File(localPath);
      final totalBytes = double.tryParse(fileMetadata.size ?? '0') ?? 0.0;
      var receivedBytes = 0.0;

      final sink = localFile.openWrite();

      // Handle the response based on its type
      if (response is http.Response) {
        // If it's a direct HTTP response
        final bytes = response.bodyBytes;
        const chunkSize = 8192; // 8KB chunks
        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end =
              (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);
          sink.add(chunk);
          receivedBytes += chunk.length.toDouble();
          if (onProgress != null) {
            onProgress(receivedBytes / totalBytes);
          }
        }
      } else if (response is drive.Media) {
        // If it's a Media object
        final stream = response.stream;
        await for (final chunk in stream) {
          sink.add(chunk);
          receivedBytes += chunk.length.toDouble();
          if (onProgress != null) {
            onProgress(receivedBytes / totalBytes);
          }
        }
      } else {
        throw Exception(
            'Unexpected response type from Google Drive API: ${response.runtimeType}');
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

  //  method to list backed up albums
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

  //  method to list files in a backed up album
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

  Future<Map<String, String>> getUserInfo() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        throw Exception('Not signed in');
      }

      _userEmail = account.email;
      return {
        'email': account.email,
        'name': account.displayName ?? account.email.split('@')[0],
        'photoUrl': account.photoUrl ?? '',
      };
    } catch (e) {
      print('Error getting user info: $e');
      rethrow;
    }
  }

  // Add method to get the backup folder URL
  Future<String?> getBackupFolderUrl() async {
    if (_driveApi == null || _folderId == null) {
      return null;
    }

    try {
      // Get the folder metadata to ensure it exists
      final folder = await _driveApi!.files.get(
        _folderId!,
        $fields: 'id,name',
      ) as drive.File;

      // Construct the Google Drive folder URL using the folder ID
      return 'https://drive.google.com/drive/folders/${folder.id}';
    } catch (e) {
      print('Error getting backup folder URL: $e');
      return null;
    }
  }

  //  method to upload a file to Google Drive
  Future<void> uploadFile(
    File file,
    String path, {
    void Function(double)? onProgress,
  }) async {
    if (!_isSignedIn || _driveApi == null || _folderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final fileMetadata = drive.File()
        ..name = path.split('/').last
        ..parents = [_folderId!];

      final media = drive.Media(
        file.openRead(),
        await file.length(),
      );

      await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      // Since we can't track progress directly, we'll just call onProgress with 1.0 when done
      if (onProgress != null) {
        onProgress(1.0);
      }
    } catch (e) {
      print('Error uploading file to Google Drive: $e');
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
