import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_realtime_client.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_repository.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';
import 'package:prowem_live_score/features/tournament/domain/tournament_snapshot.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_controller.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_providers.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_state.dart';

void main() {
  group('TournamentController', () {
    test('loads the initial snapshot and connects realtime', () async {
      final repository = FakeTournamentRepository(
        snapshots: [_initialSnapshot()],
      );

      final container = ProviderContainer.test(
        overrides: [tournamentRepositoryProvider.overrideWithValue(repository)],
      );

      final state = await container.read(tournamentControllerProvider.future);

      expect(state.snapshot.teams, hasLength(4));

      expect(repository.fetchCallCount, 1);

      await _flushEvents();

      expect(repository.connectCallCount, 1);
    });

    test('applies a realtime update', () async {
      final repository = FakeTournamentRepository(
        snapshots: [_initialSnapshot()],
      );

      final container = ProviderContainer.test(
        overrides: [tournamentRepositoryProvider.overrideWithValue(repository)],
      );

      await container.read(tournamentControllerProvider.future);

      repository.emitUpdate(
        _update(updateId: 'live-1', homeScore: 1, awayScore: 0),
      );

      await _flushEvents();

      final state = container.read(tournamentControllerProvider).requireValue;

      final game = state.snapshot.games.firstWhere((game) => game.id == 1);

      expect(game.homeScore, 1);

      expect(game.awayScore, 0);

      expect(game.status, GameStatus.inPlay);

      expect(state.snapshot.standings.first.points, 3);
    });

    test('ignores duplicate update ids', () async {
      final repository = FakeTournamentRepository(
        snapshots: [_initialSnapshot()],
      );

      final container = ProviderContainer.test(
        overrides: [tournamentRepositoryProvider.overrideWithValue(repository)],
      );

      await container.read(tournamentControllerProvider.future);

      repository.emitUpdate(
        _update(updateId: 'same-id', homeScore: 1, awayScore: 0),
      );

      await _flushEvents();

      // Same update id with deliberately different
      // content must be ignored.
      repository.emitUpdate(
        _update(updateId: 'same-id', homeScore: 9, awayScore: 0),
      );

      await _flushEvents();

      final state = container.read(tournamentControllerProvider).requireValue;

      expect(state.snapshot.games.first.homeScore, 1);
    });

    test(
      'applies PATCH response immediately and ignores its websocket duplicate',
      () async {
        final httpUpdate = _update(
          updateId: 'http-1',
          homeScore: 2,
          awayScore: 1,
        );

        final repository = FakeTournamentRepository(
          snapshots: [_initialSnapshot()],
          updateResult: httpUpdate,
        );

        final container = ProviderContainer.test(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
          ],
        );

        await container.read(tournamentControllerProvider.future);

        await container
            .read(tournamentControllerProvider.notifier)
            .updateMatchResult(
              gameId: 1,
              homeScore: 2,
              awayScore: 1,
              status: GameStatus.inPlay,
            );

        var state = container.read(tournamentControllerProvider).requireValue;

        expect(state.snapshot.games.first.homeScore, 2);

        expect(state.updatingMatchId, isNull);

        repository.emitUpdate(
          _update(updateId: 'http-1', homeScore: 99, awayScore: 1),
        );

        await _flushEvents();

        state = container.read(tournamentControllerProvider).requireValue;

        expect(state.snapshot.games.first.homeScore, 2);
      },
    );

    test('resyncs from REST after reconnect', () async {
      final repository = FakeTournamentRepository(
        snapshots: [
          _initialSnapshot(),
          _snapshotWithScore(homeScore: 3, awayScore: 2),
        ],
      );

      final container = ProviderContainer.test(
        overrides: [tournamentRepositoryProvider.overrideWithValue(repository)],
      );

      await container.read(tournamentControllerProvider.future);

      repository.emitStatus(RealtimeConnectionStatus.connected);

      await _flushEvents();

      repository.emitStatus(RealtimeConnectionStatus.reconnecting);

      await _flushEvents();

      var state = container.read(tournamentControllerProvider).requireValue;

      expect(state.syncStatus, TournamentSyncStatus.reconnecting);

      repository.emitStatus(RealtimeConnectionStatus.connected);

      await _flushEvents();
      await _flushEvents();

      state = container.read(tournamentControllerProvider).requireValue;

      expect(repository.fetchCallCount, 2);

      expect(state.snapshot.games.first.homeScore, 3);

      expect(state.snapshot.games.first.awayScore, 2);

      expect(state.syncStatus, TournamentSyncStatus.synced);
    });

    test('keeps current snapshot when a score update fails', () async {
      final repository = FakeTournamentRepository(
        snapshots: [_initialSnapshot()],
        updateError: Exception('Network failure'),
      );

      final container = ProviderContainer.test(
        overrides: [tournamentRepositoryProvider.overrideWithValue(repository)],
      );

      await container.read(tournamentControllerProvider.future);

      await container
          .read(tournamentControllerProvider.notifier)
          .updateMatchResult(
            gameId: 1,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus.inPlay,
          );

      final state = container.read(tournamentControllerProvider).requireValue;

      expect(state.snapshot.games.first.homeScore, isNull);

      expect(state.lastError, isNotNull);

      expect(state.updatingMatchId, isNull);
    });
  });
}

class FakeTournamentRepository implements TournamentRepository {
  FakeTournamentRepository({
    required List<TournamentSnapshot> snapshots,
    this.updateResult,
    this.updateError,
  }) : _snapshots = List<TournamentSnapshot>.unmodifiable(snapshots);

  final List<TournamentSnapshot> _snapshots;

  final TournamentUpdate? updateResult;
  final Object? updateError;

  final _updatesController = StreamController<TournamentUpdate>.broadcast();

  final _statusController =
      StreamController<RealtimeConnectionStatus>.broadcast();

  int fetchCallCount = 0;
  int connectCallCount = 0;
  int updateCallCount = 0;

  @override
  Stream<TournamentUpdate> get updates => _updatesController.stream;

  @override
  Stream<RealtimeConnectionStatus> get connectionStatuses =>
      _statusController.stream;

  @override
  Future<TournamentSnapshot> fetchSnapshot() async {
    final index = fetchCallCount;

    fetchCallCount++;

    if (index >= _snapshots.length) {
      return _snapshots.last;
    }

    return _snapshots[index];
  }

  @override
  Future<void> connectRealtime() async {
    connectCallCount++;
  }

  @override
  Future<TournamentUpdate> updateMatchResult({
    required int gameId,
    required int homeScore,
    required int awayScore,
    required GameStatus status,
  }) async {
    updateCallCount++;

    final error = updateError;

    if (error != null) {
      throw error;
    }

    final result = updateResult;

    if (result == null) {
      throw StateError('No fake update result configured.');
    }

    return result;
  }

  void emitUpdate(TournamentUpdate update) {
    _updatesController.add(update);
  }

  void emitStatus(RealtimeConnectionStatus status) {
    _statusController.add(status);
  }
}

TournamentSnapshot _initialSnapshot() {
  return TournamentSnapshot.fromJson({
    'teams': _teams(),
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
  });
}

TournamentSnapshot _snapshotWithScore({
  required int homeScore,
  required int awayScore,
}) {
  return TournamentSnapshot.fromJson({
    'teams': _teams(),
    'matches': [
      {
        'id': 1,
        'round_number': 1,
        'home_team_id': 1,
        'away_team_id': 2,
        'home_score': homeScore,
        'away_score': awayScore,
        'status': 'in_play',
        'kickoff_at': null,
      },
    ],
    'standings': [
      _standing(
        position: 1,
        teamId: 1,
        points: 3,
        goalDifference: homeScore - awayScore,
      ),
      _standing(position: 2, teamId: 3),
      _standing(position: 3, teamId: 4),
      _standing(position: 4, teamId: 2, goalDifference: awayScore - homeScore),
    ],
  });
}

TournamentUpdate _update({
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
      'home_team_id': 1,
      'away_team_id': 2,
      'home_score': homeScore,
      'away_score': awayScore,
      'status': 'in_play',
      'kickoff_at': null,
    },
    'standings': [
      _standing(
        position: 1,
        teamId: 1,
        points: 3,
        goalDifference: homeScore - awayScore,
      ),
      _standing(position: 2, teamId: 3),
      _standing(position: 3, teamId: 4),
      _standing(position: 4, teamId: 2, goalDifference: awayScore - homeScore),
    ],
  });
}

List<Map<String, dynamic>> _teams() {
  return [
    {'id': 1, 'name': 'Juventus', 'logo_url': null},
    {'id': 2, 'name': 'Inter', 'logo_url': null},
    {'id': 3, 'name': 'AC Milan', 'logo_url': null},
    {'id': 4, 'name': 'AS Roma', 'logo_url': null},
  ];
}

Map<String, dynamic> _standing({
  required int position,
  required int teamId,
  int points = 0,
  int goalDifference = 0,
}) {
  return {
    'position': position,
    'team_id': teamId,
    'played': points > 0 ? 1 : 0,
    'won': points == 3 ? 1 : 0,
    'drawn': 0,
    'lost': goalDifference < 0 ? 1 : 0,
    'goals_for': 0,
    'goals_against': 0,
    'goal_difference': goalDifference,
    'points': points,
  };
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);

  await Future<void>.delayed(Duration.zero);
}
