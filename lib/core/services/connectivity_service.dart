import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service that monitors device network connectivity and real internet reachability.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  final Connectivity _connectivity;
  final StreamController<bool> _connectionChangeController =
      StreamController<bool>.broadcast();

  bool _hasConnection = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService._internal({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  factory ConnectivityService({Connectivity? connectivity}) {
    return _instance;
  }

  /// Current cached connection status.
  bool get hasConnection => _hasConnection;

  /// Stream of connection status changes (true = online, false = offline).
  Stream<bool> get onConnectivityChanged => _connectionChangeController.stream;

  void _init() {
    _checkInitialConnection();
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityResultChanged);
  }

  Future<void> _checkInitialConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('[ConnectivityService] Initial check error: $e');
    }
  }

  Future<void> _onConnectivityResultChanged(List<ConnectivityResult> results) async {
    await _updateConnectionStatus(results);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final bool isPotentiallyConnected = results.any((result) => result != ConnectivityResult.none);

    bool isReallyConnected = false;
    if (isPotentiallyConnected) {
      isReallyConnected = await checkInternetAccess();
    }

    if (_hasConnection != isReallyConnected) {
      _hasConnection = isReallyConnected;
      debugPrint('[ConnectivityService] Internet status changed: ${isReallyConnected ? "ONLINE" : "OFFLINE"}');
      _connectionChangeController.add(_hasConnection);
    }
  }

  /// Actively checks internet reachability by performing a DNS lookup.
  Future<bool> checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Actively checks and updates current connection status.
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results);
      return _hasConnection;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _connectionChangeController.close();
  }
}
