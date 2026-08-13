import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({required this.baseUrl, required this.token, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _client;

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) => _send('POST', path, body: body);
  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) => _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> _send(String method, String path, {Map<String, String>? query, Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers.addAll({'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || json['success'] != true) {
      final error = json['error'] as Map<String, dynamic>?;
      throw AppException(json['message'] as String? ?? 'Request failed.', code: error?['code'] as String? ?? 'REQUEST_FAILED');
    }
    return json;
  }
}
