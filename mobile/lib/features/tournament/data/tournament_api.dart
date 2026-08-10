import 'package:dio/dio.dart';

import '../domain/game.dart';
import '../domain/tournament_snapshot.dart';

class TournamentApi {
  const TournamentApi(this._dio);

  final Dio _dio;

  Future<TournamentSnapshot> fetchSnapshot() async {
    final response = await _dio.get<Map<String, dynamic>>('/tournament');

    final data = _extractData(response.data, operation: 'fetch tournament');

    return TournamentSnapshot.fromJson(data);
  }

  Future<TournamentUpdate> updateMatchResult({
    required int gameId,
    required int homeScore,
    required int awayScore,
    required GameStatus status,
  }) async {
    if (gameId <= 0) {
      throw ArgumentError.value(gameId, 'gameId', 'Must be greater than zero.');
    }

    if (homeScore < 0) {
      throw ArgumentError.value(
        homeScore,
        'homeScore',
        'Must not be negative.',
      );
    }

    if (awayScore < 0) {
      throw ArgumentError.value(
        awayScore,
        'awayScore',
        'Must not be negative.',
      );
    }

    if (status == GameStatus.scheduled) {
      throw ArgumentError.value(
        status,
        'status',
        'A result update cannot use scheduled status.',
      );
    }

    final response = await _dio.patch<Map<String, dynamic>>(
      '/matches/$gameId/result',
      data: {
        'home_score': homeScore,
        'away_score': awayScore,
        'status': status.apiValue,
      },
    );

    final data = _extractData(response.data, operation: 'update match result');

    return TournamentUpdate.fromJson(data);
  }

  Map<String, dynamic> _extractData(
    Map<String, dynamic>? body, {
    required String operation,
  }) {
    if (body == null) {
      throw FormatException('Empty response while attempting to $operation.');
    }

    final data = body['data'];

    if (data is! Map<String, dynamic>) {
      throw FormatException(
        'Invalid API response while attempting to $operation: '
        'expected a data object.',
      );
    }

    return data;
  }
}
