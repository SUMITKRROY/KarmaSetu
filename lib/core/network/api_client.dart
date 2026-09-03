class ApiClient {
  final String baseUrl;

  const ApiClient({required this.baseUrl});

  Future<dynamic> get(String path) async {
    // TODO: Implement HTTP client (Dio/http).
    throw UnimplementedError();
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    // TODO: Implement HTTP client (Dio/http).
    throw UnimplementedError();
  }
}
