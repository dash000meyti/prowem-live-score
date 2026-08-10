import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_realtime_client.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_api.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_repository.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';
import 'package:prowem_live_score/features/tournament/domain/tournament_snapshot.dart';

void main() {
  group('TournamentRepository', () {
    test('fetchSnapshot delegates to TournamentApi', () async {
      RequestOptions? capturedRequest;

      final dio = _buildDio(
        onRequest: (options) {
          capturedRequest = options;

          return _snapshotResponse();
        },
      );

      final realtime = FakeTournamentRealtimeClient();

      final repository = DefaultTournamentRepository(
        api: TournamentApi(dio),
        realtimeClient: realtime,
      );

      final snapshot = await repository.fetchSnapshot();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'GET');
      expect(capturedRequest!.path, '/tournament');

      expect(snapshot.teams, hasLength(4));
      expect(snapshot.games, hasLength(1));
      expect(snapshot.standings, hasLength(4));

      await realtime.dispose();
    });

    test('updateMatchResult delegates to TournamentApi', () async {
      RequestOptions? capturedRequest;

      final dio = _buildDio(
        onRequest: (options) {
          capturedRequest = options;

          return _updateResponse();
        },
      );

      final realtime = FakeTournamentRealtimeClient();

      final repository = DefaultTournamentRepository(
        api: TournamentApi(dio),
        realtimeClient: realtime,
      );

      final update = await repository.updateMatchResult(
        gameId: 1,
        homeScore: 2,
        awayScore: 1,
        status: GameStatus.inPlay,
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'PATCH');
      expect(capturedRequest!.path, '/matches/1/result');

      expect(capturedRequest!.data, {
        'home_score': 2,
        'away_score': 1,
        'status': 'in_play',
      });

      expect(update.updateId, 'update-123');
      expect(update.game.homeScore, 2);
      expect(update.game.awayScore, 1);

      await realtime.dispose();
    });

    test('connectRealtime delegates to realtime client', () async {
      final realtime = FakeTournamentRealtimeClient();

      final repository = DefaultTournamentRepository(
        api: TournamentApi(_unusedDio()),
        realtimeClient: realtime,
      );

      expect(realtime.connectCallCount, 0);

      await repository.connectRealtime();

      expect(realtime.connectCallCount, 1);

      await realtime.dispose();
    });

    test('exposes realtime tournament updates', () async {
      final realtime = FakeTournamentRealtimeClient();

      final repository = DefaultTournamentRepository(
        api: TournamentApi(_unusedDio()),
        realtimeClient: realtime,
      );

      final futureUpdate = repository.updates.first;

      realtime.emitUpdate(
        _tournamentUpdate(
          updateId: 'update-live-1',
          homeScore: 1,
          awayScore: 0,
        ),
      );

      final update = await futureUpdate;

      expect(update.updateId, 'update-live-1');
      expect(update.game.homeScore, 1);
      expect(update.game.awayScore, 0);

      await realtime.dispose();
    });

    test('exposes realtime connection status changes', () async {
      final realtime = FakeTournamentRealtimeClient();

      final repository = DefaultTournamentRepository(
        api: TournamentApi(_unusedDio()),
        realtimeClient: realtime,
      );

      final statuses = <RealtimeConnectionStatus>[];

      final subscription = repository.connectionStatuses.listen(statuses.add);

      realtime.emitConnectionStatus(RealtimeConnectionStatus.connecting);

      realtime.emitConnectionStatus(RealtimeConnectionStatus.connected);

      await Future<void>.delayed(Duration.zero);

      expect(statuses, [
        RealtimeConnectionStatus.connecting,
        RealtimeConnectionStatus.connected,
      ]);

      await subscription.cancel();
      await realtime.dispose();
    });

    test(
      'does not calculate standings locally when realtime update arrives',
      () async {
        final realtime = FakeTournamentRealtimeClient();

        final repository = DefaultTournamentRepository(
          api: TournamentApi(_unusedDio()),
          realtimeClient: realtime,
        );

        final updateFuture = repository.updates.first;

        final authoritativeUpdate = _tournamentUpdate(
          updateId: 'authoritative-1',
          homeScore: 4,
          awayScore: 0,
          standings: [
            _standing(position: 1, teamId: 3, points: 99, goalDifference: 50),
            _standing(position: 2, teamId: 1, points: 3, goalDifference: 4),
          ],
        );

        realtime.emitUpdate(authoritativeUpdate);

        final received = await updateFuture;

        expect(received.standings.first.teamId, 3);
        expect(received.standings.first.points, 99);
        expect(received.standings.first.goalDifference, 50);

        await realtime.dispose();
      },
    );
  });
}

class FakeTournamentRealtimeClient implements TournamentRealtimeClient {
  final _updatesController = StreamController<TournamentUpdate>.broadcast();

  final _statusController =
      StreamController<RealtimeConnectionStatus>.broadcast();

  int connectCallCount = 0;

  @override
  Stream<TournamentUpdate> get updates {
    return _updatesController.stream;
  }

  @override
  Stream<RealtimeConnectionStatus> get connectionStatuses {
    return _statusController.stream;
  }

  @override
  Future<void> connect() async {
    connectCallCount++;
  }

  void emitUpdate(TournamentUpdate update) {
    _updatesController.add(update);
  }

  void emitConnectionStatus(RealtimeConnectionStatus status) {
    _statusController.add(status);
  }

  @override
  Future<void> dispose() async {
    await _updatesController.close();
    await _statusController.close();
  }
}

typedef ResponseFactory =
    Map<String, dynamic>? Function(RequestOptions options);

Dio _buildDio({required ResponseFactory onRequest}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:18080/api'));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: onRequest(options),
          ),
        );
      },
    ),
  );

  return dio;
}

Dio _unusedDio() {
  return Dio(BaseOptions(baseUrl: 'http://localhost:18080/api'));
}

Map<String, dynamic> _snapshotResponse() {
  return {
    'data': {
      'teams': [
        {'id': 1, 'name': 'Juventus', 'logo_url': null},
        {'id': 2, 'name': 'Inter', 'logo_url': null},
        {'id': 3, 'name': 'AC Milan', 'logo_url': null},
        {'id': 4, 'name': 'AS Roma', 'logo_url': null},
      ],
      'matches': [
        {
          'id': 1,
          'round_number': 1,
          'home_team_id': 1,
          'away_team_id': 2,
          'home_score': null,
          'away_score': null,
          'status': 'scheduled',
          'kickoff_at': null,
        },
      ],
      'standings': [
        _standing(position: 1, teamId: 1),
        _standing(position: 2, teamId: 2),
        _standing(position: 3, teamId: 3),
        _standing(position: 4, teamId: 4),
      ],
    },
  };
}

Map<String, dynamic> _updateResponse() {
  return {
    'data': {
      'update_id': 'update-123',
      'occurred_at': '2026-08-10T20:00:00.000Z',
      'match': {
        'id': 1,
        'round_number': 1,
        'home_team_id': 1,
        'away_team_id': 2,
        'home_score': 2,
        'away_score': 1,
        'status': 'in_play',
        'kickoff_at': null,
      },
      'standings': [
        _standing(
          position: 1,
          teamId: 1,
          played: 1,
          won: 1,
          goalsFor: 2,
          goalsAgainst: 1,
          goalDifference: 1,
          points: 3,
        ),
        _standing(
          position: 2,
          teamId: 2,
          played: 1,
          lost: 1,
          goalsFor: 1,
          goalsAgainst: 2,
          goalDifference: -1,
        ),
      ],
    },
  };
}

TournamentUpdate _tournamentUpdate({
  required String updateId,
  required int homeScore,
  required int awayScore,
  List<Map<String, dynamic>>? standings,
}) {
  return TournamentUpdate.fromJson({
    'update_id': updateId,
    'occurred_at': '2026-08-10T20:00:00.000Z',
    'match': {
      'id': 1,
      'round_number': 1,
      'home_team_id': 1,
      'away_team_id': 2,
      'home_score': homeScore,
      'away_score': awayScore,
      'status': 'in_play',
      'kickoff_at': null,
    },
    'standings':
        standings ??
        [
          _standing(
            position: 1,
            teamId: 1,
            played: 1,
            won: 1,
            goalsFor: homeScore,
            goalsAgainst: awayScore,
            goalDifference: homeScore - awayScore,
            points: 3,
          ),
          _standing(
            position: 2,
            teamId: 2,
            played: 1,
            lost: 1,
            goalsFor: awayScore,
            goalsAgainst: homeScore,
            goalDifference: awayScore - homeScore,
          ),
        ],
  });
}

Map<String, dynamic> _standing({
  required int position,
  required int teamId,
  int played = 0,
  int won = 0,
  int drawn = 0,
  int lost = 0,
  int goalsFor = 0,
  int goalsAgainst = 0,
  int goalDifference = 0,
  int points = 0,
}) {
  return {
    'position': position,
    'team_id': teamId,
    'played': played,
    'won': won,
    'drawn': drawn,
    'lost': lost,
    'goals_for': goalsFor,
    'goals_against': goalsAgainst,
    'goal_difference': goalDifference,
    'points': points,
  };
}
