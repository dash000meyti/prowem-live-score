import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_realtime_client.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_repository.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';
import 'package:prowem_live_score/features/tournament/domain/tournament_snapshot.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_providers.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_screen.dart';
import 'package:prowem_live_score/features/tournament/presentation/widgets/animated_standings_table.dart';

void main() {
  group('TournamentScreen', () {
    testWidgets(
      'loads snapshot then applies realtime score and animated standings update',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repository = FakeTournamentRepository(
          initialSnapshot: _initialSnapshot(),
        );

        addTearDown(repository.dispose);

        await tester.pumpWidget(_testApp(repository));

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('LIVE TOURNAMENT'), findsOneWidget);

        expect(find.text('SYNCED'), findsOneWidget);

        expect(find.text('NEXT MATCH'), findsOneWidget);

        final matchFinder = find.byKey(const ValueKey('featured-match-1'));

        expect(matchFinder, findsOneWidget);

        expect(
          find.descendant(of: matchFinder, matching: find.text('Inter')),
          findsOneWidget,
        );

        expect(
          find.descendant(of: matchFinder, matching: find.text('Juventus')),
          findsOneWidget,
        );

        expect(
          find.descendant(of: matchFinder, matching: find.text('0')),
          findsNWidgets(2),
        );

        final standingsFinder = find.byType(AnimatedStandingsTable);

        final juventusRow = find.byKey(const ValueKey('standing-row-1'));

        final interRow = find.byKey(const ValueKey('standing-row-2'));

        expect(standingsFinder, findsOneWidget);

        expect(juventusRow, findsOneWidget);

        expect(interRow, findsOneWidget);

        final standingsInitialTop = tester.getTopLeft(standingsFinder).dy;

        final juventusInitialRelativeY =
            tester.getTopLeft(juventusRow).dy - standingsInitialTop;

        final interInitialRelativeY =
            tester.getTopLeft(interRow).dy - standingsInitialTop;

        expect(juventusInitialRelativeY, lessThan(interInitialRelativeY));

        repository.emitUpdate(
          _liveUpdate(updateId: 'live-update-1', homeScore: 1, awayScore: 0),
        );

        // First pump delivers the asynchronous realtime event.
        //
        // The second pump renders the Riverpod state update without
        // advancing the standings animation.
        await tester.pump();
        await tester.pump();

        expect(
          find.descendant(of: matchFinder, matching: find.text('1')),
          findsOneWidget,
        );

        expect(
          find.descendant(of: matchFinder, matching: find.text('LIVE MATCH')),
          findsOneWidget,
        );

        expect(
          find.descendant(of: matchFinder, matching: find.text('LIVE')),
          findsOneWidget,
        );

        // The featured match card grows when it changes from
        // scheduled to live. That moves the entire standings table
        // vertically on screen.
        //
        // Therefore animation must be measured relative to the
        // standings table itself instead of using absolute screen Y.
        await tester.pump(const Duration(milliseconds: 200));

        final standingsMidTop = tester.getTopLeft(standingsFinder).dy;

        final juventusMidRelativeY =
            tester.getTopLeft(juventusRow).dy - standingsMidTop;

        final interMidRelativeY =
            tester.getTopLeft(interRow).dy - standingsMidTop;

        expect(interMidRelativeY, lessThan(interInitialRelativeY));

        expect(juventusMidRelativeY, greaterThan(juventusInitialRelativeY));

        await tester.pumpAndSettle();

        final standingsFinalTop = tester.getTopLeft(standingsFinder).dy;

        final juventusFinalRelativeY =
            tester.getTopLeft(juventusRow).dy - standingsFinalTop;

        final interFinalRelativeY =
            tester.getTopLeft(interRow).dy - standingsFinalTop;

        expect(interFinalRelativeY, lessThan(juventusFinalRelativeY));

        expect(repository.connectCallCount, 1);
      },
    );

    testWidgets('ignores duplicate realtime updates with the same update id', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = FakeTournamentRepository(
        initialSnapshot: _initialSnapshot(),
      );

      addTearDown(repository.dispose);

      await tester.pumpWidget(_testApp(repository));

      await tester.pump();
      await tester.pumpAndSettle();

      final matchFinder = find.byKey(const ValueKey('featured-match-1'));

      expect(matchFinder, findsOneWidget);

      repository.emitUpdate(
        _liveUpdate(updateId: 'duplicate-id', homeScore: 1, awayScore: 0),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: matchFinder, matching: find.text('1')),
        findsOneWidget,
      );

      // Send the same update_id with intentionally different data.
      // The controller must ignore it.
      repository.emitUpdate(
        _liveUpdate(updateId: 'duplicate-id', homeScore: 9, awayScore: 0),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: matchFinder, matching: find.text('9')),
        findsNothing,
      );

      expect(
        find.descendant(of: matchFinder, matching: find.text('1')),
        findsOneWidget,
      );
    });
  });
}

Widget _testApp(TournamentRepository repository) {
  return ProviderScope(
    overrides: [tournamentRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: TournamentScreen()),
  );
}

class FakeTournamentRepository implements TournamentRepository {
  FakeTournamentRepository({required this.initialSnapshot});

  final TournamentSnapshot initialSnapshot;

  final StreamController<TournamentUpdate> _updatesController =
      StreamController<TournamentUpdate>.broadcast();

  final StreamController<RealtimeConnectionStatus> _statusController =
      StreamController<RealtimeConnectionStatus>.broadcast();

  int fetchCallCount = 0;
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
  Future<TournamentSnapshot> fetchSnapshot() async {
    fetchCallCount++;

    return initialSnapshot;
  }

  @override
  Future<void> connectRealtime() async {
    connectCallCount++;

    _statusController.add(RealtimeConnectionStatus.connected);
  }

  @override
  Future<TournamentUpdate> updateMatchResult({
    required int gameId,
    required int homeScore,
    required int awayScore,
    required GameStatus status,
  }) async {
    throw UnsupportedError('Score mutation is not used in this test.');
  }

  void emitUpdate(TournamentUpdate update) {
    _updatesController.add(update);
  }

  Future<void> dispose() async {
    await _updatesController.close();
    await _statusController.close();
  }
}

TournamentSnapshot _initialSnapshot() {
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

        // Inter is intentionally the home team.
        //
        // All initial standings values are equal, so team id is
        // the final deterministic ranking tie breaker. Juventus
        // begins above Inter. When Inter scores it becomes first,
        // producing a genuine ranking movement.
        'home_team_id': 2,
        'away_team_id': 1,
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
  });
}

TournamentUpdate _liveUpdate({
  required String updateId,
  required int homeScore,
  required int awayScore,
}) {
  return TournamentUpdate.fromJson({
    'update_id': updateId,
    'occurred_at': '2026-08-10T20:00:00.000Z',
    'match': {
      'id': 1,
      'round_number': 1,
      'home_team_id': 2,
      'away_team_id': 1,
      'home_score': homeScore,
      'away_score': awayScore,
      'status': 'in_play',
      'kickoff_at': null,
    },
    'standings': [
      _standing(
        position: 1,
        teamId: 2,
        played: 1,
        won: 1,
        goalsFor: homeScore,
        goalsAgainst: awayScore,
        goalDifference: homeScore - awayScore,
        points: 3,
      ),
      _standing(position: 2, teamId: 3),
      _standing(position: 3, teamId: 4),
      _standing(
        position: 4,
        teamId: 1,
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
