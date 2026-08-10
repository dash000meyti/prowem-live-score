import '../domain/game.dart';
import '../domain/tournament_snapshot.dart';
import 'tournament_api.dart';
import 'tournament_realtime_client.dart';

abstract interface class TournamentRepository {
  Stream<TournamentUpdate> get updates;

  Stream<RealtimeConnectionStatus> get connectionStatuses;

  Future<TournamentSnapshot> fetchSnapshot();

  Future<TournamentUpdate> updateMatchResult({
    required int gameId,
    required int homeScore,
    required int awayScore,
    required GameStatus status,
  });

  Future<void> connectRealtime();
}

final class DefaultTournamentRepository implements TournamentRepository {
  factory DefaultTournamentRepository({
    required TournamentApi api,
    required TournamentRealtimeClient realtimeClient,
  }) {
    return DefaultTournamentRepository._(api, realtimeClient);
  }

  const DefaultTournamentRepository._(this._api, this._realtimeClient);

  final TournamentApi _api;

  final TournamentRealtimeClient _realtimeClient;

  @override
  Stream<TournamentUpdate> get updates => _realtimeClient.updates;

  @override
  Stream<RealtimeConnectionStatus> get connectionStatuses =>
      _realtimeClient.connectionStatuses;

  @override
  Future<TournamentSnapshot> fetchSnapshot() {
    return _api.fetchSnapshot();
  }

  @override
  Future<TournamentUpdate> updateMatchResult({
    required int gameId,
    required int homeScore,
    required int awayScore,
    required GameStatus status,
  }) {
    return _api.updateMatchResult(
      gameId: gameId,
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
    );
  }

  @override
  Future<void> connectRealtime() {
    return _realtimeClient.connect();
  }
}
