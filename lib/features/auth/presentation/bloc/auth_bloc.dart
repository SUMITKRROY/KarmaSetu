import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUserChanged>(_onAuthUserChanged);
    on<AuthSeedRequested>(_onAuthSeedRequested);

    // Listen to Firebase auth state stream
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      add(AuthUserChanged(user));
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } on fb.FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'user-not-found' => 'User not found. Please register or use Quick Test Sign-in.',
        'wrong-password' => 'Wrong password provided.',
        'invalid-credential' => 'Invalid email or password.',
        'invalid-email' => 'The email address is badly formatted.',
        'user-disabled' => 'This user account has been disabled.',
        'too-many-requests' => 'Too many failed attempts. Please wait a moment.',
        'network-request-failed' => 'Network error. Please check your connection.',
        'operation-not-allowed' => 'Email/Password sign-in is not enabled in Firebase console.',
        _ => e.message ?? 'Authentication failed. Please check credentials.',
      };
      emit(AuthError(message));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
        employeeId: event.employeeId,
        role: event.role,
        site: event.site,
        department: event.department,
      );
      emit(AuthAuthenticated(user));
    } on fb.FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' => 'The password provided is too weak (minimum 6 characters).',
        'invalid-email' => 'The email address is not valid.',
        'operation-not-allowed' => 'Email/Password sign-in is not enabled in Firebase console.',
        'network-request-failed' => 'Network error. Please check your connection.',
        _ => e.message ?? 'Registration failed. Please try again.',
      };
      emit(AuthError(message));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Failed to logout: $e'));
      emit(const AuthUnauthenticated());
    }
  }

  void _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthSeedRequested(
    AuthSeedRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.seedDefaultUsers();
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
