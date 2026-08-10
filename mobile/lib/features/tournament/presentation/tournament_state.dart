import '../domain/game.dart';
import '../domain/tournament_snapshot.dart';

enum TournamentSyncStatus {
  connecting,
  syncing,
  synced,
  reconnecting,
  resyncing,
  degraded,
}

class FailedMatchMutation {
  const FailedMatchMutation({
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

class TournamentState {
  const TournamentState({
    required this.snapshot,
    required this.syncStatus,
    required this.lastConfirmedAt,
    this.updatingMatchId,
    this.lastError,
    this.failedMutation,
    this.matchConfirmedAt = const <int, DateTime>{},
  });

  final TournamentSnapshot snapshot;
  final TournamentSyncStatus syncStatus;

  /// The match mutation currently being sent to the server.
  ///
  /// Mutations are serialized by TournamentController so server responses
  /// cannot overwrite each other out of order.
  final int? updatingMatchId;

  /// Latest server-confirmed tournament activity.
  ///
  /// Used by the compact match list footer.
  final DateTime lastConfirmedAt;

  /// Latest confirmed time for each individual match.
  ///
  /// A score update in match B must not visually refresh the "Last update"
  /// label of match A.
  final Map<int, DateTime> matchConfirmedAt;

  /// Non-fatal error. Initial loading errors remain represented by AsyncValue.
  final Object? lastError;

  /// Exact failed mutation so Retry can replay it.
  final FailedMatchMutation? failedMutation;

  bool get hasFailedMutation => failedMutation != null;

  DateTime? confirmedAtForMatch(int gameId) => matchConfirmedAt[gameId];

  TournamentState copyWith({
    TournamentSnapshot? snapshot,
    TournamentSyncStatus? syncStatus,
    int? updatingMatchId,
    bool clearUpdatingMatch = false,
    DateTime? lastConfirmedAt,
    Map<int, DateTime>? matchConfirmedAt,
    Object? lastError,
    bool clearError = false,
    FailedMatchMutation? failedMutation,
    bool clearFailedMutation = false,
  }) {
    return TournamentState(
      snapshot: snapshot ?? this.snapshot,
      syncStatus: syncStatus ?? this.syncStatus,
      updatingMatchId: clearUpdatingMatch
          ? null
          : updatingMatchId ?? this.updatingMatchId,
      lastConfirmedAt: lastConfirmedAt ?? this.lastConfirmedAt,
      matchConfirmedAt: matchConfirmedAt ?? this.matchConfirmedAt,
      lastError: clearError ? null : lastError ?? this.lastError,
      failedMutation: clearFailedMutation
          ? null
          : failedMutation ?? this.failedMutation,
    );
  }
}
