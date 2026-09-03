abstract interface class LocalStorage {
  Future<void> write(String key, dynamic value);
  dynamic read(String key);
  Future<void> remove(String key);
  Future<void> clear();
}
