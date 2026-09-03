class User {
  final String uid;
  final String name;
  final String email;
  final String employeeId;
  final String role; // "employee" | "approver" | "admin"
  final String site;
  final String department;

  const User({
    required this.uid,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.role,
    required this.site,
    required this.department,
  });

  bool get isApprover => role.toLowerCase() == 'approver' || role.toLowerCase() == 'manager';
  bool get isEmployee => role.toLowerCase() == 'employee';

  User copyWith({
    String? uid,
    String? name,
    String? email,
    String? employeeId,
    String? role,
    String? site,
    String? department,
  }) {
    return User(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      site: site ?? this.site,
      department: department ?? this.department,
    );
  }
}
