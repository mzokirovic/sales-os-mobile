import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_storage.dart';
import 'api_config.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    AuthStorage? authStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _authStorage = authStorage ?? AuthStorage();

  final http.Client _httpClient;
  final AuthStorage _authStorage;

  Uri _uri(String path) {
    return Uri.parse('${ApiConfig.baseUrl}$path');
  }

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (withAuth) {
      final token = await _authStorage.readAccessToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String path) async {
    final response = await _httpClient.get(
      _uri(path),
      headers: await _headers(),
    );

    return _decode(response);
  }

  Future<dynamic> post(
    String path, {
    required Map<String, dynamic> body,
    bool withAuth = true,
  }) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  Future<dynamic> patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.patch(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map<String, dynamic>
        ? body['message']?.toString() ?? 'API error'
        : 'API error';

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
    );
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}
