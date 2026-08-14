import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/event_card.dart';
import '../models/event_card_model.dart';

class EventsRemoteDataSource {
  EventsRemoteDataSource(
      {required this.baseUrl, required this.token, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _client;

  Future<EventSummary> getSummary() async {
    final json = await _get('/events/summary');
    return EventSummary((json['data'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value as int)));
  }

  Future<List<EventCardModel>> getEvents(
      {String filter = 'all', String search = ''}) async {
    final query = <String, String>{'per_page': '100', 'sort': 'starts_at'};
    if (filter == 'needs_attention') query['needs_attention'] = '1';
    if (!const {'all', 'needs_attention'}.contains(filter)) {
      query['status'] = filter;
    }
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    final uri = Uri.parse('$baseUrl/events').replace(queryParameters: query);
    final json = await _request(uri);
    return (json['data'] as List<dynamic>)
        .map((item) => EventCardModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _get(String path) =>
      _request(Uri.parse('$baseUrl$path'));

  Future<Map<String, dynamic>> _request(Uri uri) async {
    late http.Response response;
    try {
      response = await _client.get(uri, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const AppException(
          'Event Care is unavailable. Check your connection and try again.',
          code: 'NETWORK_UNAVAILABLE');
    }
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const AppException('Event Care returned an invalid response.',
          code: 'INVALID_RESPONSE');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        json['success'] != true) {
      throw AppException(json['message'] as String? ?? 'Unable to load events.',
          code: response.statusCode == 401
              ? 'AUTH_REQUIRED'
              : 'EVENTS_FAILED');
    }
    return json;
  }
}
