import '../domain/tournament_snapshot.dart';

enum RealtimeConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

abstract interface class TournamentRealtimeClient {
  Stream<TournamentUpdate> get updates;

  Stream<RealtimeConnectionStatus> get connectionStatuses;

  Future<void> connect();

  Future<void> dispose();
}
