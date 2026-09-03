import '../services/connectivity_service.dart';

abstract interface class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onStatusChange;
}

class NetworkInfoImpl implements NetworkInfo {
  final ConnectivityService _connectivityService;

  NetworkInfoImpl({ConnectivityService? connectivityService})
      : _connectivityService = connectivityService ?? ConnectivityService.instance;

  @override
  Future<bool> get isConnected async => await _connectivityService.checkConnection();

  @override
  Stream<bool> get onStatusChange => _connectivityService.onConnectivityChanged;
}
