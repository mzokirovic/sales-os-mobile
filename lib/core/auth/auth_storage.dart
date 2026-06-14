import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'accessToken';
  static const _currentUserKey = 'currentUser';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<bool> hasAccessToken() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveCurrentUserJson(String userJson) async {
    return _storage.write(key: _currentUserKey, value: userJson);
  }

  Future<String?> readCurrentUserJson() {
    return _storage.read(key: _currentUserKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _currentUserKey);
  }
}
