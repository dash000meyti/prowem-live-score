import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/features/tournament/domain/standing.dart';

void main() {
  group('Standing.fromJson', () {
    test('parses a complete standing row', () {
      final standing = Standing.fromJson({
        'position': 1,
        'team_id': 1,
        'played': 3,
        'won': 2,
        'drawn': 1,
        'lost': 0,
        'goals_for': 6,
        'goals_against': 2,
        'goal_difference': 4,
        'points': 7,
      });

      expect(standing.position, 1);
      expect(standing.teamId, 1);
      expect(standing.played, 3);
      expect(standing.won, 2);
      expect(standing.drawn, 1);
      expect(standing.lost, 0);
      expect(standing.goalsFor, 6);
      expect(standing.goalsAgainst, 2);
      expect(standing.goalDifference, 4);
      expect(standing.points, 7);
    });

    test('supports a negative goal difference', () {
      final standing = Standing.fromJson({
        'position': 4,
        'team_id': 4,
        'played': 3,
        'won': 0,
        'drawn': 1,
        'lost': 2,
        'goals_for': 2,
        'goals_against': 6,
        'goal_difference': -4,
        'points': 1,
      });

      expect(standing.goalDifference, -4);
      expect(standing.points, 1);
    });
  });
}
