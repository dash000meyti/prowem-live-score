import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_api.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';

void main() {
  group('TournamentApi.fetchSnapshot', () {
    test(
      'requests GET /tournament and parses the Laravel resource envelope',
      () async {
        RequestOptions? capturedRequest;

        final dio = _buildDio(
          onRequest: (options) {
            capturedRequest = options;

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
          },
        );

        final api = TournamentApi(dio);

        final snapshot = await api.fetchSnapshot();

        expect(capturedRequest, isNotNull);
        expect(capturedRequest!.method, 'GET');
        expect(capturedRequest!.path, '/tournament');

        expect(snapshot.teams, hasLength(4));
        expect(snapshot.games, hasLength(1));
        expect(snapshot.standings, hasLength(4));

        expect(snapshot.teams[0].name, 'Juventus');
        expect(snapshot.teams[1].name, 'Inter');
        expect(snapshot.teams[2].name, 'AC Milan');
        expect(snapshot.teams[3].name, 'AS Roma');

        expect(snapshot.games.first.status, GameStatus.scheduled);

        expect(
          snapshot.standings.every((standing) => standing.points == 0),
          isTrue,
        );
      },
    );

    test('throws when the response body is empty', () async {
      final dio = _buildDio(onRequest: (_) => null);

      final api = TournamentApi(dio);

      expect(api.fetchSnapshot, throwsA(isA<FormatException>()));
    });

    test('throws when Laravel data envelope is missing', () async {
      final dio = _buildDio(onRequest: (_) => {'message': 'OK'});

      final api = TournamentApi(dio);

      expect(api.fetchSnapshot, throwsA(isA<FormatException>()));
    });

    test('throws when data is not an object', () async {
      final dio = _buildDio(onRequest: (_) => {'data': []});

      final api = TournamentApi(dio);

      expect(api.fetchSnapshot, throwsA(isA<FormatException>()));
    });
  });

  group('TournamentApi.updateMatchResult', () {
    test('PATCHes the result endpoint with the expected payload', () async {
      RequestOptions? capturedRequest;

      final dio = _buildDio(
        onRequest: (options) {
          capturedRequest = options;

          return {
            'data': {
              'update_id': 'update-123',
              'occurred_at': '2026-08-10T20:00:00.000Z',
              'match': {
                'id': 5,
                'round_number': 3,
                'home_team_id': 1,
                'away_team_id': 4,
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
                _standing(position: 2, teamId: 2),
                _standing(position: 3, teamId: 3),
                _standing(
                  position: 4,
                  teamId: 4,
                  played: 1,
                  lost: 1,
                  goalsFor: 1,
                  goalsAgainst: 2,
                  goalDifference: -1,
                ),
              ],
            },
          };
        },
      );

      final api = TournamentApi(dio);

      final update = await api.updateMatchResult(
        gameId: 5,
        homeScore: 2,
        awayScore: 1,
        status: GameStatus.inPlay,
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'PATCH');

      expect(capturedRequest!.path, '/matches/5/result');

      expect(capturedRequest!.data, {
        'home_score': 2,
        'away_score': 1,
        'status': 'in_play',
      });

      expect(update.updateId, 'update-123');
      expect(update.game.id, 5);
      expect(update.game.homeScore, 2);
      expect(update.game.awayScore, 1);
      expect(update.game.status, GameStatus.inPlay);

      expect(update.standings.first.teamId, 1);
      expect(update.standings.first.points, 3);
    });

    test('serializes finished status correctly', () async {
      RequestOptions? capturedRequest;

      final dio = _buildDio(
        onRequest: (options) {
          capturedRequest = options;

          return _updateResponse(status: 'finished');
        },
      );

      final api = TournamentApi(dio);

      await api.updateMatchResult(
        gameId: 1,
        homeScore: 1,
        awayScore: 1,
        status: GameStatus.finished,
      );

      final data = capturedRequest!.data as Map<String, dynamic>;

      expect(data['status'], 'finished');
    });

    test('rejects scheduled status before making a network request', () async {
      var requestCount = 0;

      final dio = _buildDio(
        onRequest: (_) {
          requestCount++;
          return _updateResponse();
        },
      );

      final api = TournamentApi(dio);

      await expectLater(
        () => api.updateMatchResult(
          gameId: 1,
          homeScore: 0,
          awayScore: 0,
          status: GameStatus.scheduled,
        ),
        throwsArgumentError,
      );

      expect(requestCount, 0);
    });

    test(
      'rejects a negative home score before making a network request',
      () async {
        var requestCount = 0;

        final dio = _buildDio(
          onRequest: (_) {
            requestCount++;
            return _updateResponse();
          },
        );

        final api = TournamentApi(dio);

        await expectLater(
          () => api.updateMatchResult(
            gameId: 1,
            homeScore: -1,
            awayScore: 0,
            status: GameStatus.inPlay,
          ),
          throwsArgumentError,
        );

        expect(requestCount, 0);
      },
    );

    test(
      'rejects a negative away score before making a network request',
      () async {
        var requestCount = 0;

        final dio = _buildDio(
          onRequest: (_) {
            requestCount++;
            return _updateResponse();
          },
        );

        final api = TournamentApi(dio);

        await expectLater(
          () => api.updateMatchResult(
            gameId: 1,
            homeScore: 0,
            awayScore: -1,
            status: GameStatus.inPlay,
          ),
          throwsArgumentError,
        );

        expect(requestCount, 0);
      },
    );

    test(
      'rejects an invalid game id before making a network request',
      () async {
        var requestCount = 0;

        final dio = _buildDio(
          onRequest: (_) {
            requestCount++;
            return _updateResponse();
          },
        );

        final api = TournamentApi(dio);

        await expectLater(
          () => api.updateMatchResult(
            gameId: 0,
            homeScore: 0,
            awayScore: 0,
            status: GameStatus.inPlay,
          ),
          throwsArgumentError,
        );

        expect(requestCount, 0);
      },
    );
  });
}

typedef TestResponseFactory =
    Map<String, dynamic>? Function(RequestOptions options);

Dio _buildDio({required TestResponseFactory onRequest}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:18080/api',
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final body = onRequest(options);

        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: body,
          ),
        );
      },
    ),
  );

  return dio;
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

Map<String, dynamic> _updateResponse({String status = 'in_play'}) {
  return {
    'data': {
      'update_id': 'update-test',
      'occurred_at': '2026-08-10T20:00:00.000Z',
      'match': {
        'id': 1,
        'round_number': 1,
        'home_team_id': 1,
        'away_team_id': 2,
        'home_score': 1,
        'away_score': 1,
        'status': status,
        'kickoff_at': null,
      },
      'standings': [
        _standing(
          position: 1,
          teamId: 1,
          played: 1,
          drawn: 1,
          goalsFor: 1,
          goalsAgainst: 1,
          points: 1,
        ),
        _standing(
          position: 2,
          teamId: 2,
          played: 1,
          drawn: 1,
          goalsFor: 1,
          goalsAgainst: 1,
          points: 1,
        ),
      ],
    },
  };
}
