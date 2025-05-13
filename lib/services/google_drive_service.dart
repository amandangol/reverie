import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class GoogleDriveService {
  static const String _appFolderName = 'ReverieBackup';
  static const String _credentialsKey = 'google_drive_credentials';

  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
  ]);

  drive.DriveApi? _driveApi;
  String? _folderId;

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<void> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return;

      final GoogleSignInAuthentication auth = await account.authentication;
      final client = GoogleAuthClient(auth.accessToken!);
      _driveApi = drive.DriveApi(client);

      // Create or get app folder
      _folderId = await _getOrCreateAppFolder();
    } catch (e) {
      print('Error signing in to Google Drive: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
    _folderId = null;
  }

  Future<String?> _getOrCreateAppFolder() async {
    if (_driveApi == null) return null;

    try {
      // Search for existing folder
      final result = await _driveApi!.files.list(
        q: "name = '$_appFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'appDataFolder',
      );

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }

      // Create new folder if not found
      final folder = drive.File()
        ..name = _appFolderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = ['appDataFolder'];

      final createdFolder = await _driveApi!.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      print('Error getting/creating app folder: $e');
      rethrow;
    }
  }

  Future<void> backupFile(File file, String fileName) async {
    if (_driveApi == null || _folderId == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final fileStream = file.openRead();
      final fileSize = await file.length();

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [_folderId!];

      await _driveApi!.files.create(
        driveFile,
        uploadMedia: drive.Media(fileStream, fileSize),
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
        spaces: 'appDataFolder',
      );

      return result.files ?? [];
    } catch (e) {
      print('Error listing backed up files: $e');
      rethrow;
    }
  }

  Future<void> restoreFile(String fileId, String localPath) async {
    if (_driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as http.Response;

      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);
    } catch (e) {
      print('Error restoring file: $e');
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
