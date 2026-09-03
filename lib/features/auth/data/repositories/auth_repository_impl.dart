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

    if (localUser != null) {
      // User is authenticated locally. Attempt a quick remote sync without blocking offline startup.
      try {
        final remoteUser = await remoteDataSource.getCurrentUser().timeout(
          const Duration(milliseconds: 1000),
        );
        if (remoteUser != null) {
          await localDataSource.saveUser(UserModel.fromUser(remoteUser));
          return remoteUser;
        }
      } catch (_) {
        // Offline or remote timeout: seamlessly return the cached local user
      }
      return localUser;
    }

    // 2. If no local user exists, query Firebase with a timeout
    try {
      final remoteUser = await remoteDataSource.getCurrentUser().timeout(
        const Duration(milliseconds: 2000),
      );
      if (remoteUser != null) {
        await localDataSource.saveUser(UserModel.fromUser(remoteUser));
        return remoteUser;
      }
    } catch (_) {}

    return null;
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
      }
      // Never delete local credentials on stream null events (which happen when offline).
      // Only explicit logout() clears the local user.
      return user;
    });
  }

  @override
  Future<void> seedDefaultUsers() {
    return remoteDataSource.seedDefaultUsers();
  }
}
