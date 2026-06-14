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

  Future<CurrentUser> login({
    required String phone,
    required String password,
  }) async {
    final result = await _apiClient.post(
      '/auth/login',
      withAuth: false,
      body: {
        'phone': phone,
        'password': password,
      },
    );

    if (result is! Map<String, dynamic>) {
      throw const AuthException('Login javobi noto‘g‘ri formatda keldi');
    }

    final accessToken = result['accessToken']?.toString();

    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException('Access token kelmadi');
    }

    await _authStorage.saveAccessToken(accessToken);

    final userJson = result['user'];

    if (userJson is Map<String, dynamic>) {
      return CurrentUser.fromJson(userJson);
    }

    final meResult = await _apiClient.get('/auth/me');

    if (meResult is! Map<String, dynamic>) {
      throw const AuthException('User ma’lumotlari noto‘g‘ri formatda keldi');
    }

    return CurrentUser.fromJson(meResult);
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
