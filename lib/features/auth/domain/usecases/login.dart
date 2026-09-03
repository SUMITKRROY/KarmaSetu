import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Login {
  final AuthRepository repository;

  const Login(this.repository);

  Future<User> call(String username, String password) {
    return repository.login(username, password);
  }
}
