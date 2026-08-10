import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/app/app_theme.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_realtime_client.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_repository.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';
import 'package:prowem_live_score/features/tournament/domain/tournament_snapshot.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_providers.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_screen.dart';

void main() {
  testWidgets('shows quick scoring controls for every live match', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _FakeTournamentRepository(
      snapshot: _snapshotWithTwoLiveMatches(),
    );

    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tournamentRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const TournamentScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('featured-match-1')), findsOneWidget);

    expect(find.byKey(const ValueKey('featured-match-2')), findsOneWidget);

    // Each live match exposes one goal button
    // for each participating team.
    expect(find.text('+ GOAL'), findsNWidgets(4));

    expect(find.text('LIVE MATCH'), findsNWidgets(2));
  });
}

class _FakeTournamentRepository implements TournamentRepository {
  _FakeTournamentRepository({required this.snapshot});

  final TournamentSnapshot snapshot;

  final StreamController<TournamentUpdate> _updates =
      StreamController<TournamentUpdate>.broadcast();

  final StreamController<RealtimeConnectionStatus> _statuses =
      StreamController<RealtimeConnectionStatus>.broadcast();

  @override
  Stream<TournamentUpdate> get updates => _updates.stream;

  @override
  Stream<RealtimeConnectionStatus> get connectionStatuses => _statuses.stream;

  @override
  Future<TournamentSnapshot> fetchSnapshot() async {
    return snapshot;
  }

  @override
  Future<void> connectRealtime() async {
    _statuses.add(RealtimeConnectionStatus.connected);
  }

  @override
  Future<TournamentUpdate> updateMatchResult({
    required int gameId,
    required int homeScore,
    required int awayScore,
    required GameStatus status,
  }) {
    throw UnsupportedError('Mutations are not used in this test.');
  }

  Future<void> dispose() async {
    await _updates.close();
    await _statuses.close();
  }
}

TournamentSnapshot _snapshotWithTwoLiveMatches() {
  return TournamentSnapshot.fromJson({
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
        'away_team_id': 4,
        'home_score': 1,
        'away_score': 0,
        'status': 'in_play',
        'kickoff_at': null,
      },
      {
        'id': 2,
        'round_number': 1,
        'home_team_id': 2,
        'away_team_id': 3,
        'home_score': 0,
        'away_score': 2,
        'status': 'in_play',
        'kickoff_at': null,
      },
    ],
    'standings': [
      _standing(
        position: 1,
        teamId: 3,
        played: 1,
        won: 1,
        goalDifference: 2,
        points: 3,
      ),
      _standing(
        position: 2,
        teamId: 1,
        played: 1,
        won: 1,
        goalDifference: 1,
        points: 3,
      ),
      _standing(position: 3, teamId: 4, played: 1, lost: 1, goalDifference: -1),
      _standing(position: 4, teamId: 2, played: 1, lost: 1, goalDifference: -2),
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
