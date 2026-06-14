import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_storage.dart';
import '../../../core/auth/current_user.dart';

class AuthRepository {
  AuthRepository({
    ApiClient? apiClient,
    AuthStorage? authStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authStorage = authStorage ?? AuthStorage();

  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  Future<CurrentUser?> bootstrapUser() async {
    final hasToken = await _authStorage.hasAccessToken();

    if (!hasToken) {
      return null;
    }

    final cachedUserJson = await _authStorage.readCurrentUserJson();
    final cachedUser = CurrentUser.fromStorageJson(cachedUserJson);

    if (cachedUser != null) {
      return cachedUser;
    }

    try {
      final meResult = await _apiClient.get('/auth/me');

      if (meResult is! Map<String, dynamic>) {
        await _authStorage.clear();
        return null;
      }

      final user = CurrentUser.fromJson(meResult);
      await _authStorage.saveCurrentUserJson(user.toStorageJson());

      return user;
    } catch (_) {
      await _authStorage.clear();
      return null;
    }
  }

  Future<CurrentUser> login({
    required String phone,
    required String password,
  }) async {
    final result = await _apiClient.post(
      '/auth/login',
      body: {
        'phone': phone,
        'password': password,
      },
      withAuth: false,
    );

    if (result is! Map<String, dynamic>) {
      throw const AuthException('Login javobi noto‘g‘ri formatda keldi');
    }

    final token = result['accessToken'] as String?;
    final userJson = result['user'];

    if (token == null || token.isEmpty) {
      throw const AuthException('Token kelmadi');
    }

    await _authStorage.saveAccessToken(token);

    CurrentUser user;

    if (userJson is Map<String, dynamic>) {
      user = CurrentUser.fromJson(userJson);
    } else {
      final meResult = await _apiClient.get('/auth/me');

      if (meResult is! Map<String, dynamic>) {
        throw const AuthException('Foydalanuvchi ma’lumoti kelmadi');
      }

      user = CurrentUser.fromJson(meResult);
    }

    await _authStorage.saveCurrentUserJson(user.toStorageJson());

    return user;
  }

  Future<CurrentUser?> readCurrentUser() async {
    final json = await _authStorage.readCurrentUserJson();
    return CurrentUser.fromStorageJson(json);
  }

  Future<void> logout() {
    return _authStorage.clear();
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
