import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  const AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<UserModel> login(String username, String password) async {
    final response = await apiClient.post(
      '/login',
      data: {'username': username, 'password': password},
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }
}
