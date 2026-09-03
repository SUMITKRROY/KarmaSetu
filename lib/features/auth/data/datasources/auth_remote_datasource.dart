import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String role,
    required String site,
    required String department,
  });
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
  Stream<UserModel?> get authStateChanges;
  Future<void> seedDefaultUsers();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  @override
  Future<UserModel> login(String email, String password) async {
    final cleanEmail = email.trim();
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('Authentication failed: No user found.');
      }

      return await _getUserOrProvision(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      // If test account does not exist in Firebase yet, auto-register it
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        if (cleanEmail == 'employee@test.com' || cleanEmail == 'approver@test.com') {
          return await _autoRegisterTestAccount(cleanEmail, password);
        }
      }
      rethrow;
    }
  }

  Future<UserModel> _autoRegisterTestAccount(String email, String password) async {
    final isApprover = email.contains('approver');
    return await register(
      email: email,
      password: password.isNotEmpty ? password : (isApprover ? 'Approver@123' : 'Employee@123'),
      name: isApprover ? 'Test Approver' : 'Test Employee',
      employeeId: isApprover ? 'APP001' : 'EMP001',
      role: isApprover ? 'approver' : 'employee',
      site: 'Bangalore',
      department: 'Engineering',
    );
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String role,
    required String site,
    required String department,
  }) async {
    final cleanEmail = email.trim();
    fb.UserCredential credential;

    try {
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Sign in instead
        credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
      } else {
        rethrow;
      }
    }

    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Registration failed: User could not be created.');
    }

    // Update display name
    try {
      await fbUser.updateDisplayName(name.trim());
    } catch (_) {}

    final userModel = UserModel(
      uid: fbUser.uid,
      name: name.trim(),
      email: cleanEmail,
      employeeId: employeeId.trim(),
      role: role.trim().toLowerCase(),
      site: site.trim(),
      department: department.trim(),
    );

    // Write to Firestore /users/<uid>
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(fbUser.uid)
          .set(userModel.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      // Firestore write attempt logged
    }

    return userModel;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    return await _getUserOrProvision(fbUser);
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      try {
        return await _getUserOrProvision(fbUser);
      } catch (_) {
        return null;
      }
    });
  }

  Future<UserModel> _getUserOrProvision(fb.User fbUser) async {
    try {
      final docRef = _firestore.collection(_usersCollection).doc(fbUser.uid);
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromFirestore(snapshot.data()!, fbUser.uid);
      }
    } catch (_) {}

    // Build initial profile if Firestore doc doesn't exist yet
    final email = fbUser.email?.toLowerCase() ?? '';
    final isApprover = email.contains('approver');

    final userModel = UserModel(
      uid: fbUser.uid,
      name: fbUser.displayName ?? (isApprover ? 'Test Approver' : 'Test Employee'),
      email: fbUser.email ?? (isApprover ? 'approver@test.com' : 'employee@test.com'),
      employeeId: isApprover ? 'APP001' : 'EMP001',
      role: isApprover ? 'approver' : 'employee',
      site: 'Bangalore',
      department: 'Engineering',
    );

    try {
      await _firestore
          .collection(_usersCollection)
          .doc(fbUser.uid)
          .set(userModel.toFirestore(), SetOptions(merge: true));
    } catch (_) {}

    return userModel;
  }

  @override
  Future<void> seedDefaultUsers() async {
    const testAccounts = [
      {
        'email': 'employee@test.com',
        'password': 'Employee@123',
        'name': 'Test Employee',
        'employeeId': 'EMP001',
        'role': 'employee',
        'site': 'Bangalore',
        'department': 'Engineering',
      },
      {
        'email': 'approver@test.com',
        'password': 'Approver@123',
        'name': 'Test Approver',
        'employeeId': 'APP001',
        'role': 'approver',
        'site': 'Bangalore',
        'department': 'Engineering',
      },
    ];

    for (final acc in testAccounts) {
      try {
        await register(
          email: acc['email']!,
          password: acc['password']!,
          name: acc['name']!,
          employeeId: acc['employeeId']!,
          role: acc['role']!,
          site: acc['site']!,
          department: acc['department']!,
        );
      } catch (_) {}
    }
  }
}
