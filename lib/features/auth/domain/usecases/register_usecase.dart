import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  Future<User> call({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String role,
    required String site,
    required String department,
  }) {
    return repository.register(
      email: email,
      password: password,
      name: name,
      employeeId: employeeId,
      role: role,
      site: site,
      department: department,
    );
  }
}
