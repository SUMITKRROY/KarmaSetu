import '../models/user_model.dart';

abstract interface class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);
  UserModel? getUser();
  Future<void> clearUser();
}
