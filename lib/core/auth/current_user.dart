import 'dart:convert';

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.tenantId,
    required this.fullName,
    required this.phone,
    required this.role,
  });

  final String id;
  final String tenantId;
  final String fullName;
  final String phone;
  final String role;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'fullName': fullName,
      'phone': phone,
      'role': role,
    };
  }

  String toStorageJson() {
    return jsonEncode(toJson());
  }

  static CurrentUser? fromStorageJson(String? value) {
    if (value == null || value.isEmpty) return null;

    final decoded = jsonDecode(value);

    if (decoded is! Map<String, dynamic>) return null;

    return CurrentUser.fromJson(decoded);
  }
}
