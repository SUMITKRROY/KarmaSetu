import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String role,
    required String site,
    required String department,
  });
  Future<User?> getCurrentUser();
  Future<User?> getLocalUser();
  Future<void> logout();
  Stream<User?> get authStateChanges;
  Future<void> seedDefaultUsers();
}
