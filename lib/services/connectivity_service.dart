import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool _isConnected = true;

  Future<void> initialize() async {
    // Check initial connection
    await checkConnection();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged
        .listen((ConnectivityResult result) async {
      await checkConnection();
    });
  }

  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _isConnected = false;
    }
    _connectionStatusController.add(_isConnected);
    return _isConnected;
  }

  bool get isConnected => _isConnected;

  void dispose() {
    _connectionStatusController.close();
  }
}

class NoInternetException implements Exception {
  final String message;
  NoInternetException(
      [this.message =
          'No internet connection. Please check your connection and try again.']);

  @override
  String toString() => message;
}
