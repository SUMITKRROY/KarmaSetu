import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';

@immutable
sealed class AuthEvent {
  const AuthEvent();
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });
}

final class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String employeeId;
  final String role;
  final String site;
  final String department;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.employeeId,
    required this.role,
    required this.site,
    required this.department,
  });
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthUserChanged extends AuthEvent {
  final User? user;

  const AuthUserChanged(this.user);
}

final class AuthSeedRequested extends AuthEvent {
  const AuthSeedRequested();
}
