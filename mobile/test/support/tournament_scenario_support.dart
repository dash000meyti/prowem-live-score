import 'dart:async';
import 'dart:collection';

import 'package:prowem_live_score/features/tournament/data/tournament_realtime_client.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_repository.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';
import 'package:prowem_live_score/features/tournament/domain/tournament_snapshot.dart';

class MutationCall {
  const MutationCall({
    required this.gameId,
    required this.homeScore,
    required this.awayScore,
    required this.status,
  });

  final int gameId;
  final int homeScore;
  final int awayScore;
  final GameStatus status;
}

class ScenarioTournamentRepository implements TournamentRepository {
  ScenarioTournamentRepository({
    required List<TournamentSnapshot> snapshots,
    this.emitConnectedOnConnect = true,
  }) : _snapshots = List<TournamentSnapshot>.of(snapshots);

  final List<TournamentSnapshot> _snapshots;
  final bool emitConnectedOnConnect;

  final StreamController<TournamentUpdate> _updatesController =
      StreamController<TournamentUpdate>.broadcast();

  final StreamController<RealtimeConnectionStatus> _statusController =
      StreamController<RealtimeConnectionStatus>.broadcast();

  final List<MutationCall> mutationCalls = <MutationCall>[];
  final Queue<Completer<TournamentUpdate>> _pendingMutations =
      Queue<Completer<TournamentUpdate>>();

  int fetchCallCount = 0;
  int connectCallCount = 0;

  bool holdMutations = false;
  Object? mutationError;

  TournamentUpdate Function(MutationCall call)? responseFactory;

  int get pendingMutationCount => _pendingMutations.length;

  @override
  Stream<TournamentUpdate> get updates => _updatesController.stream;

  @override
  Stream<RealtimeConnectionStatus> get connectionStatuses =>
      _statusController.stream;

  @override
  Future<TournamentSnapshot> fetchSnapshot() async {
    fetchCallCount++;

    if (_snapshots.isEmpty) {
      throw StateError('Scenario repository has no snapshots.');
    }

    final index = fetchCallCount - 1;

    return _snapshots[index < _snapshots.length
        ? index
        : _snapshots.length - 1];
  }

  @override
  Future<void> connectRealtime() async {
    connectCallCount++;

    if (emitConnectedOnConnect) {
      _statusController.add(RealtimeConnectionStatus.connected);
    }
  }

  @override
  Future<TournamentUpdate> updateMatchResult({
    required int gameId,
    required int homeScore,
    required int awayScore,
    required GameStatus status,
  }) async {
    final call = MutationCall(
      gameId: gameId,
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
    );

    mutationCalls.add(call);

    final error = mutationError;

    if (error != null) {
      throw error;
    }

    if (holdMutations) {
      final completer = Completer<TournamentUpdate>();
      _pendingMutations.addLast(completer);
      return completer.future;
    }

    final factory = responseFactory;

    if (factory == null) {
      throw StateError(
        'No responseFactory configured for immediate mutation response.',
      );
    }

    return factory(call);
  }

  void completeNextMutation(TournamentUpdate update) {
    if (_pendingMutations.isEmpty) {
      throw StateError('No pending mutation to complete.');
    }

    _pendingMutations.removeFirst().complete(update);
  }

  void failNextMutation(Object error) {
    if (_pendingMutations.isEmpty) {
      throw StateError('No pending mutation to fail.');
    }

    _pendingMutations.removeFirst().completeError(error);
  }

  void emitUpdate(TournamentUpdate update) {
    _updatesController.add(update);
  }

  void emitStatus(RealtimeConnectionStatus status) {
    _statusController.add(status);
  }

  Future<void> dispose() async {
    while (_pendingMutations.isNotEmpty) {
      final completer = _pendingMutations.removeFirst();

      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Scenario repository disposed with pending mutation.'),
        );
      }
    }

    await _updatesController.close();
    await _statusController.close();
  }
}

TournamentSnapshot scenarioSnapshot({
  required List<Map<String, dynamic>> matches,
  required List<Map<String, dynamic>> standings,
}) {
  return TournamentSnapshot.fromJson({
    'teams': scenarioTeams(),
    'matches': matches,
    'standings': standings,
  });
}

List<Map<String, dynamic>> scenarioTeams() {
  return [
    {'id': 1, 'name': 'Juventus', 'logo_url': null},
    {'id': 2, 'name': 'Inter', 'logo_url': null},
    {'id': 3, 'name': 'AC Milan', 'logo_url': null},
    {'id': 4, 'name': 'AS Roma', 'logo_url': null},
  ];
}

Map<String, dynamic> matchJson({
  required int id,
  required int round,
  required int homeTeamId,
  required int awayTeamId,
  required GameStatus status,
  int? homeScore,
  int? awayScore,
}) {
  return {
    'id': id,
    'round_number': round,
    'home_team_id': homeTeamId,
    'away_team_id': awayTeamId,
    'home_score': homeScore,
    'away_score': awayScore,
    'status': status.apiValue,
    'kickoff_at': null,
  };
}

Map<String, dynamic> standingJson({
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

TournamentUpdate scenarioUpdate({
  required String updateId,
  required int gameId,
  required int round,
  required int homeTeamId,
  required int awayTeamId,
  required int homeScore,
  required int awayScore,
  required GameStatus status,
  required List<Map<String, dynamic>> standings,
  String occurredAt = '2026-08-10T20:00:00.000Z',
}) {
  return TournamentUpdate.fromJson({
    'update_id': updateId,
    'occurred_at': occurredAt,
    'match': matchJson(
      id: gameId,
      round: round,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
    ),
    'standings': standings,
  });
}

List<Map<String, dynamic>> neutralStandings() {
  return [
    standingJson(position: 1, teamId: 1),
    standingJson(position: 2, teamId: 2),
    standingJson(position: 3, teamId: 3),
    standingJson(position: 4, teamId: 4),
  ];
}

List<Map<String, dynamic>> standingsAfterJuventusWin({
  required int homeScore,
  required int awayScore,
}) {
  return [
    standingJson(
      position: 1,
      teamId: 1,
      played: 1,
      won: 1,
      goalsFor: homeScore,
      goalsAgainst: awayScore,
      goalDifference: homeScore - awayScore,
      points: 3,
    ),
    standingJson(position: 2, teamId: 2),
    standingJson(position: 3, teamId: 3),
    standingJson(
      position: 4,
      teamId: 4,
      played: 1,
      lost: 1,
      goalsFor: awayScore,
      goalsAgainst: homeScore,
      goalDifference: awayScore - homeScore,
    ),
  ];
}

List<Map<String, dynamic>> standingsAfterInterWin({
  required int homeScore,
  required int awayScore,
}) {
  return [
    standingJson(
      position: 1,
      teamId: 2,
      played: 1,
      won: 1,
      goalsFor: homeScore,
      goalsAgainst: awayScore,
      goalDifference: homeScore - awayScore,
      points: 3,
    ),
    standingJson(position: 2, teamId: 1),
    standingJson(position: 3, teamId: 4),
    standingJson(
      position: 4,
      teamId: 3,
      played: 1,
      lost: 1,
      goalsFor: awayScore,
      goalsAgainst: homeScore,
      goalDifference: awayScore - homeScore,
    ),
  ];
}

Future<void> flushScenarioEvents([int turns = 3]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
