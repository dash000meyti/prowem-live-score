import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';

void main() {
  group('GameStatus.fromApi', () {
    test('maps scheduled', () {
      expect(GameStatus.fromApi('scheduled'), GameStatus.scheduled);
    });

    test('maps in_play', () {
      expect(GameStatus.fromApi('in_play'), GameStatus.inPlay);
    });

    test('maps finished', () {
      expect(GameStatus.fromApi('finished'), GameStatus.finished);
    });

    test('throws for an unknown status', () {
      expect(
        () => GameStatus.fromApi('cancelled'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('GameStatus.apiValue', () {
    test('serializes scheduled', () {
      expect(GameStatus.scheduled.apiValue, 'scheduled');
    });

    test('serializes inPlay', () {
      expect(GameStatus.inPlay.apiValue, 'in_play');
    });

    test('serializes finished', () {
      expect(GameStatus.finished.apiValue, 'finished');
    });
  });

  group('Game.fromJson', () {
    test('parses a scheduled game with null scores', () {
      final game = Game.fromJson({
        'id': 1,
        'round_number': 1,
        'home_team_id': 1,
        'away_team_id': 2,
        'home_score': null,
        'away_score': null,
        'status': 'scheduled',
        'kickoff_at': null,
      });

      expect(game.id, 1);
      expect(game.roundNumber, 1);
      expect(game.homeTeamId, 1);
      expect(game.awayTeamId, 2);
      expect(game.homeScore, isNull);
      expect(game.awayScore, isNull);
      expect(game.status, GameStatus.scheduled);
      expect(game.kickoffAt, isNull);
    });

    test('parses an in-play game', () {
      final game = Game.fromJson({
        'id': 4,
        'round_number': 2,
        'home_team_id': 3,
        'away_team_id': 4,
        'home_score': 2,
        'away_score': 1,
        'status': 'in_play',
        'kickoff_at': '2026-08-10T18:30:00.000Z',
      });

      expect(game.id, 4);
      expect(game.homeScore, 2);
      expect(game.awayScore, 1);
      expect(game.status, GameStatus.inPlay);

      expect(game.kickoffAt?.toUtc(), DateTime.utc(2026, 8, 10, 18, 30));
    });

    test('accepts additional API fields it does not need', () {
      final game = Game.fromJson({
        'id': 1,
        'round_number': 1,
        'home_team_id': 1,
        'away_team_id': 2,
        'home_score': 1,
        'away_score': 0,
        'status': 'finished',
        'kickoff_at': null,
        'home_team': {'id': 1, 'name': 'Juventus'},
        'away_team': {'id': 2, 'name': 'Inter'},
      });

      expect(game.status, GameStatus.finished);
      expect(game.homeScore, 1);
      expect(game.awayScore, 0);
    });
  });
}
