import '../../../../core/storage/table/profile_table.dart';
import '../models/user_model.dart';

abstract interface class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final ProfileTable _profileTable;

  AuthLocalDataSourceImpl({ProfileTable? profileTable})
      : _profileTable = profileTable ?? ProfileTable();

  @override
  Future<void> saveUser(UserModel user) async {
    await _profileTable.insert(user.toFirestore());
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final list = await _profileTable.getAll();
      if (list.isNotEmpty) {
        return UserModel.fromJson(list.first);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> clearUser() async {
    try {
      await _profileTable.deleteAll();
    } catch (_) {}
  }
}
