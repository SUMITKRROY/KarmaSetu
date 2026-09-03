import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.employeeId,
    required super.role,
    required super.site,
    required super.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: (json['uid'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
      site: json['site'] as String? ?? 'Bangalore',
      department: json['department'] as String? ?? 'Engineering',
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: data['uid'] as String? ?? uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      role: data['role'] as String? ?? 'employee',
      site: data['site'] as String? ?? 'Bangalore',
      department: data['department'] as String? ?? 'Engineering',
    );
  }

  factory UserModel.fromUser(User user) {
    return UserModel(
      uid: user.uid,
      name: user.name,
      email: user.email,
      employeeId: user.employeeId,
      role: user.role,
      site: user.site,
      department: user.department,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'name': name,
        'email': email,
        'employeeId': employeeId,
        'role': role,
        'site': site,
        'department': department,
      };

  Map<String, dynamic> toJson() => toFirestore();
}
