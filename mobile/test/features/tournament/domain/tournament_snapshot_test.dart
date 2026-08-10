import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';
import 'package:prowem_live_score/features/tournament/domain/tournament_snapshot.dart';

void main() {
  group('TournamentSnapshot.fromJson', () {
    test('parses teams, matches and standings', () {
      final snapshot = TournamentSnapshot.fromJson({
        'teams': [
          {'id': 1, 'name': 'Juventus', 'logo_url': null},
          {'id': 2, 'name': 'Inter', 'logo_url': null},
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
          {
            'position': 1,
            'team_id': 1,
            'played': 0,
            'won': 0,
            'drawn': 0,
            'lost': 0,
            'goals_for': 0,
            'goals_against': 0,
            'goal_difference': 0,
            'points': 0,
          },
          {
            'position': 2,
            'team_id': 2,
            'played': 0,
            'won': 0,
            'drawn': 0,
            'lost': 0,
            'goals_for': 0,
            'goals_against': 0,
            'goal_difference': 0,
            'points': 0,
          },
        ],
      });

      expect(snapshot.teams, hasLength(2));
      expect(snapshot.games, hasLength(1));
      expect(snapshot.standings, hasLength(2));

      expect(snapshot.teams.first.name, 'Juventus');
      expect(snapshot.games.first.status, GameStatus.scheduled);
      expect(snapshot.standings.first.teamId, 1);
    });
  });

  group('TournamentUpdate.fromJson', () {
    test('parses a realtime tournament update', () {
      final update = TournamentUpdate.fromJson({
        'update_id': 'update-123',
        'occurred_at': '2026-08-10T20:00:00.000Z',
        'match': {
          'id': 1,
          'round_number': 1,
          'home_team_id': 1,
          'away_team_id': 2,
          'home_score': 1,
          'away_score': 0,
          'status': 'in_play',
          'kickoff_at': null,
        },
        'standings': [
          {
            'position': 1,
            'team_id': 1,
            'played': 1,
            'won': 1,
            'drawn': 0,
            'lost': 0,
            'goals_for': 1,
            'goals_against': 0,
            'goal_difference': 1,
            'points': 3,
          },
          {
            'position': 2,
            'team_id': 2,
            'played': 1,
            'won': 0,
            'drawn': 0,
            'lost': 1,
            'goals_for': 0,
            'goals_against': 1,
            'goal_difference': -1,
            'points': 0,
          },
        ],
      });

      expect(update.updateId, 'update-123');
      expect(update.occurredAt.toUtc(), DateTime.utc(2026, 8, 10, 20));

      expect(update.game.id, 1);
      expect(update.game.homeScore, 1);
      expect(update.game.awayScore, 0);
      expect(update.game.status, GameStatus.inPlay);

      expect(update.standings, hasLength(2));
      expect(update.standings.first.points, 3);
    });
  });

  group('TournamentSnapshot.applyUpdate', () {
    test(
      'replaces the updated match and uses authoritative standings from backend',
      () {
        final original = TournamentSnapshot.fromJson({
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
            {
              'id': 2,
              'round_number': 1,
              'home_team_id': 3,
              'away_team_id': 4,
              'home_score': null,
              'away_score': null,
              'status': 'scheduled',
              'kickoff_at': null,
            },
          ],
          'standings': [
            _standing(position: 1, teamId: 1, points: 0, goalDifference: 0),
            _standing(position: 2, teamId: 2, points: 0, goalDifference: 0),
            _standing(position: 3, teamId: 3, points: 0, goalDifference: 0),
            _standing(position: 4, teamId: 4, points: 0, goalDifference: 0),
          ],
        });

        final update = TournamentUpdate.fromJson({
          'update_id': 'update-456',
          'occurred_at': '2026-08-10T20:05:00.000Z',
          'match': {
            'id': 1,
            'round_number': 1,
            'home_team_id': 1,
            'away_team_id': 2,
            'home_score': 2,
            'away_score': 0,
            'status': 'in_play',
            'kickoff_at': null,
          },
          'standings': [
            _standing(
              position: 1,
              teamId: 1,
              points: 3,
              goalDifference: 2,
              played: 1,
              won: 1,
              goalsFor: 2,
            ),
            _standing(position: 2, teamId: 3, points: 0, goalDifference: 0),
            _standing(position: 3, teamId: 4, points: 0, goalDifference: 0),
            _standing(
              position: 4,
              teamId: 2,
              points: 0,
              goalDifference: -2,
              played: 1,
              lost: 1,
              goalsAgainst: 2,
            ),
          ],
        });

        final updated = original.applyUpdate(update);

        expect(updated.teams, same(original.teams));

        expect(updated.games, hasLength(2));

        final updatedGame = updated.games.firstWhere((game) => game.id == 1);

        expect(updatedGame.homeScore, 2);
        expect(updatedGame.awayScore, 0);
        expect(updatedGame.status, GameStatus.inPlay);

        final untouchedGame = updated.games.firstWhere((game) => game.id == 2);

        expect(untouchedGame.homeScore, isNull);
        expect(untouchedGame.status, GameStatus.scheduled);

        expect(updated.standings.first.teamId, 1);
        expect(updated.standings.first.points, 3);
        expect(updated.standings.first.goalDifference, 2);

        expect(updated.standings.last.teamId, 2);
        expect(updated.standings.last.position, 4);
      },
    );

    test('does not mutate the original snapshot', () {
      final original = TournamentSnapshot.fromJson({
        'teams': [
          {'id': 1, 'name': 'Juventus', 'logo_url': null},
          {'id': 2, 'name': 'Inter', 'logo_url': null},
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
          _standing(position: 1, teamId: 1, points: 0, goalDifference: 0),
          _standing(position: 2, teamId: 2, points: 0, goalDifference: 0),
        ],
      });

      final update = TournamentUpdate.fromJson({
        'update_id': 'update-789',
        'occurred_at': '2026-08-10T20:10:00.000Z',
        'match': {
          'id': 1,
          'round_number': 1,
          'home_team_id': 1,
          'away_team_id': 2,
          'home_score': 1,
          'away_score': 0,
          'status': 'in_play',
          'kickoff_at': null,
        },
        'standings': [
          _standing(position: 1, teamId: 1, points: 3, goalDifference: 1),
          _standing(position: 2, teamId: 2, points: 0, goalDifference: -1),
        ],
      });

      final updated = original.applyUpdate(update);

      expect(original.games.first.homeScore, isNull);
      expect(original.games.first.status, GameStatus.scheduled);

      expect(updated.games.first.homeScore, 1);
      expect(updated.games.first.status, GameStatus.inPlay);
    });
  });
}

Map<String, dynamic> _standing({
  required int position,
  required int teamId,
  required int points,
  required int goalDifference,
  int played = 0,
  int won = 0,
  int drawn = 0,
  int lost = 0,
  int goalsFor = 0,
  int goalsAgainst = 0,
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
