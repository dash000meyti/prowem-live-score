import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/errors/app_exception.dart';
import '../models/auth_session_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<AuthSessionModel> login({required String email, required String password}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'device_name': 'event-care-mobile'}),
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || json['success'] != true) {
      final error = json['error'] as Map<String, dynamic>?;
      throw AppException(json['message'] as String? ?? 'Unable to sign in.', code: error?['code'] as String? ?? 'LOGIN_FAILED');
    }
    return AuthSessionModel.fromJson(json);
  }
}
