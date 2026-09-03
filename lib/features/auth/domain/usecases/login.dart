import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Login {
  final AuthRepository repository;

  const Login(this.repository);

  Future<User> call(String email, String password) {
    return repository.login(email: email, password: password);
  }
}
