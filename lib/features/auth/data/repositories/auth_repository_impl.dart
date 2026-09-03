import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<User> login({required String email, required String password}) async {
    final user = await remoteDataSource.login(email, password);
    // Persist immediately to our local SQLite storage
    await localDataSource.saveUser(UserModel.fromUser(user));
    return user;
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String role,
    required String site,
    required String department,
  }) async {
    final user = await remoteDataSource.register(
      email: email,
      password: password,
      name: name,
      employeeId: employeeId,
      role: role,
      site: site,
      department: department,
    );
    // Persist immediately to our local SQLite storage
    await localDataSource.saveUser(UserModel.fromUser(user));
    return user;
  }

  @override
  Future<User?> getCurrentUser() async {
    // 1. Check local SQLite storage first
    final localUser = await localDataSource.getUser();

    // 2. Query Firebase to sync any updates
    final remoteUser = await remoteDataSource.getCurrentUser();
    if (remoteUser != null) {
      await localDataSource.saveUser(UserModel.fromUser(remoteUser));
      return remoteUser;
    }

    return localUser;
  }

  @override
  Future<User?> getLocalUser() async {
    return await localDataSource.getUser();
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.clearUser();
  }

  @override
  Stream<User?> get authStateChanges {
    return remoteDataSource.authStateChanges.asyncMap((user) async {
      if (user != null) {
        await localDataSource.saveUser(UserModel.fromUser(user));
      } else {
        await localDataSource.clearUser();
      }
      return user;
    });
  }

  @override
  Future<void> seedDefaultUsers() {
    return remoteDataSource.seedDefaultUsers();
  }
}
