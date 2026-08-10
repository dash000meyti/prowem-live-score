import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tournament_realtime_client.dart';
import '../data/tournament_repository.dart';
import '../domain/game.dart';
import '../domain/tournament_snapshot.dart';
import 'tournament_providers.dart';
import 'tournament_state.dart';

final tournamentControllerProvider =
    AsyncNotifierProvider<TournamentController, TournamentState>(
      TournamentController.new,
    );

class TournamentController extends AsyncNotifier<TournamentState> {
  static const int _maxRememberedUpdateIds = 200;

  late TournamentRepository _repository;

  StreamSubscription<TournamentUpdate>? _updateSubscription;
  StreamSubscription<RealtimeConnectionStatus>? _connectionSubscription;

  final Set<String> _handledUpdateIds = <String>{};
  final Queue<String> _handledUpdateOrder = Queue<String>();

  /// Score/result mutations are intentionally serialized.
  ///
  /// We do not drop a second mutation for the same match. If two user intents
  /// arrive while the first request is still pending (for example 1-0 followed
  /// by 2-0), both are processed in order so the latest requested score wins.
  ///
  /// This also prevents slower HTTP responses from overwriting newer results.
  final Queue<_QueuedMatchMutation> _mutationQueue =
      Queue<_QueuedMatchMutation>();

  RealtimeConnectionStatus _realtimeStatus =
      RealtimeConnectionStatus.connecting;

  bool _hasConnectedOnce = false;
  bool _resyncing = false;
  bool _processingMutationQueue = false;
  bool _disposed = false;

  @override
  Future<TournamentState> build() async {
    _repository = ref.watch(tournamentRepositoryProvider);
    ref.onDispose(_dispose);

    final snapshot = await _repository.fetchSnapshot();
    final confirmedAt = DateTime.now().toUtc();

    _listenToRealtime();

    // Return the REST snapshot immediately, then establish realtime transport.
    unawaited(Future<void>.delayed(Duration.zero, _connectRealtime));

    return TournamentState(
      snapshot: snapshot,
      syncStatus: TournamentSyncStatus.connecting,
      lastConfirmedAt: confirmedAt,
      matchConfirmedAt: Map<int, DateTime>.unmodifiable({
        for (final game in snapshot.games) game.id: confirmedAt,
      }),
    );
  }

  void _listenToRealtime() {
    _updateSubscription ??= _repository.updates.listen(
      _handleRealtimeUpdate,
      onError: (Object error, StackTrace stackTrace) {
        _setNonFatalError(error);
      },
    );

    _connectionSubscription ??= _repository.connectionStatuses.listen(
      (status) {
        unawaited(_handleConnectionStatus(status));
      },
      onError: (Object error, StackTrace stackTrace) {
        _setNonFatalError(error);
      },
    );
  }

  Future<void> _connectRealtime() async {
    if (_disposed) {
      return;
    }

    try {
      await _repository.connectRealtime();
    } catch (error) {
      _realtimeStatus = RealtimeConnectionStatus.reconnecting;
      _setSyncStatus(TournamentSyncStatus.reconnecting);
      _setNonFatalError(error);
    }
  }

  void _handleRealtimeUpdate(TournamentUpdate update) {
    _applyUpdate(update);
  }

  bool _applyUpdate(TournamentUpdate update) {
    if (_disposed || _handledUpdateIds.contains(update.updateId)) {
      return false;
    }

    final current = state.value;

    if (current == null) {
      return false;
    }

    try {
      final nextSnapshot = current.snapshot.applyUpdate(update);

      final matchConfirmedAt = Map<int, DateTime>.of(current.matchConfirmedAt)
        ..[update.game.id] = update.occurredAt;

      _rememberUpdateId(update.updateId);

      state = AsyncData(
        current.copyWith(
          snapshot: nextSnapshot,
          lastConfirmedAt: update.occurredAt,
          matchConfirmedAt: Map<int, DateTime>.unmodifiable(matchConfirmedAt),
          clearError: !current.hasFailedMutation,
        ),
      );

      return true;
    } catch (error) {
      _setNonFatalError(error);
      return false;
    }
  }

  void _rememberUpdateId(String updateId) {
    if (!_handledUpdateIds.add(updateId)) {
      return;
    }

    _handledUpdateOrder.addLast(updateId);

    while (_handledUpdateOrder.length > _maxRememberedUpdateIds) {
      final expired = _handledUpdateOrder.removeFirst();
      _handledUpdateIds.remove(expired);
    }
  }

  Future<void> _handleConnectionStatus(RealtimeConnectionStatus status) async {
    if (_disposed) {
      return;
    }

    _realtimeStatus = status;

    switch (status) {
      case RealtimeConnectionStatus.connecting:
        if (!_hasActiveFailure) {
          _setSyncStatus(TournamentSyncStatus.connecting);
        }

      case RealtimeConnectionStatus.connected:
        if (!_hasConnectedOnce) {
          _hasConnectedOnce = true;

          if (!_hasActiveFailure) {
            _setSyncStatus(TournamentSyncStatus.synced);
          }

          return;
        }

        await _resyncSnapshot();

      case RealtimeConnectionStatus.disconnected:
      case RealtimeConnectionStatus.reconnecting:
        if (!_hasActiveFailure) {
          _setSyncStatus(TournamentSyncStatus.reconnecting);
        }
    }
  }

  bool get _hasActiveFailure {
    final current = state.value;
    return current?.syncStatus == TournamentSyncStatus.degraded;
  }

  TournamentSyncStatus _syncStatusForRealtime() {
    return switch (_realtimeStatus) {
      RealtimeConnectionStatus.connected => TournamentSyncStatus.synced,
      RealtimeConnectionStatus.connecting => TournamentSyncStatus.connecting,
      RealtimeConnectionStatus.disconnected ||
      RealtimeConnectionStatus.reconnecting =>
        TournamentSyncStatus.reconnecting,
    };
  }

  Future<void> _resyncSnapshot() async {
    if (_resyncing || _disposed) {
      return;
    }

    final current = state.value;

    if (current == null) {
      return;
    }

    _resyncing = true;

    state = AsyncData(
      current.copyWith(
        syncStatus: TournamentSyncStatus.resyncing,
        clearError: !current.hasFailedMutation,
      ),
    );

    try {
      final snapshot = await _repository.fetchSnapshot();

      if (_disposed) {
        return;
      }

      final latest = state.value;

      if (latest == null) {
        return;
      }

      final confirmedAt = DateTime.now().toUtc();

      state = AsyncData(
        latest.copyWith(
          snapshot: snapshot,
          syncStatus: latest.hasFailedMutation
              ? TournamentSyncStatus.degraded
              : TournamentSyncStatus.synced,
          lastConfirmedAt: confirmedAt,
          matchConfirmedAt: Map<int, DateTime>.unmodifiable({
            for (final game in snapshot.games) game.id: confirmedAt,
          }),
          clearError: !latest.hasFailedMutation,
        ),
      );
    } catch (error) {
      final latest = state.value;

      if (latest != null && !_disposed) {
        state = AsyncData(
          latest.copyWith(
            syncStatus: TournamentSyncStatus.degraded,
            lastError: error,
          ),
        );
      }
    } finally {
      _resyncing = false;
    }
  }

  Future<void> refreshSnapshot() async {
    final current = state.value;

    if (current == null || _disposed || _resyncing) {
      return;
    }

    _resyncing = true;

    state = AsyncData(
      current.copyWith(
        syncStatus: TournamentSyncStatus.resyncing,
        clearError: !current.hasFailedMutation,
      ),
    );

    try {
      final snapshot = await _repository.fetchSnapshot();

      if (_disposed) {
        return;
      }

      final latest = state.value;

      if (latest == null) {
        return;
      }

      final confirmedAt = DateTime.now().toUtc();

      state = AsyncData(
        latest.copyWith(
          snapshot: snapshot,
          syncStatus: latest.hasFailedMutation
              ? TournamentSyncStatus.degraded
              : _syncStatusForRealtime(),
          lastConfirmedAt: confirmedAt,
          matchConfirmedAt: Map<int, DateTime>.unmodifiable({
            for (final game in snapshot.games) game.id: confirmedAt,
          }),
          clearError: !latest.hasFailedMutation,
        ),
      );
    } catch (error) {
      final latest = state.value;

      if (latest != null && !_disposed) {
        state = AsyncData(
          latest.copyWith(
            syncStatus: TournamentSyncStatus.degraded,
            lastError: error,
          ),
        );
      }
    } finally {
      _resyncing = false;
    }
  }

  Future<void> updateMatchResult({
    required int gameId,
    required int homeScore,
    required int awayScore,
    required GameStatus status,
  }) {
    if (_disposed) {
      return Future<void>.value();
    }

    final completer = Completer<void>();

    _mutationQueue.addLast(
      _QueuedMatchMutation(
        mutation: FailedMatchMutation(
          gameId: gameId,
          homeScore: homeScore,
          awayScore: awayScore,
          status: status,
        ),
        completer: completer,
      ),
    );

    unawaited(_drainMutationQueue());

    return completer.future;
  }

  Future<void> _drainMutationQueue() async {
    if (_processingMutationQueue || _disposed) {
      return;
    }

    _processingMutationQueue = true;

    try {
      while (_mutationQueue.isNotEmpty && !_disposed) {
        final queued = _mutationQueue.removeFirst();

        try {
          await _submitMutation(queued.mutation);

          if (!queued.completer.isCompleted) {
            queued.completer.complete();
          }
        } catch (error, stackTrace) {
          if (!queued.completer.isCompleted) {
            queued.completer.completeError(error, stackTrace);
          }
        }
      }
    } finally {
      _processingMutationQueue = false;
    }
  }

  Future<void> retryLastFailure() async {
    final current = state.value;

    if (current == null || _disposed) {
      return;
    }

    final failedMutation = current.failedMutation;

    if (failedMutation != null) {
      await updateMatchResult(
        gameId: failedMutation.gameId,
        homeScore: failedMutation.homeScore,
        awayScore: failedMutation.awayScore,
        status: failedMutation.status,
      );
      return;
    }

    await refreshSnapshot();
  }

  Future<void> _submitMutation(FailedMatchMutation mutation) async {
    final current = state.value;

    if (current == null || _disposed) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        syncStatus: TournamentSyncStatus.syncing,
        updatingMatchId: mutation.gameId,
        clearError: true,
        clearFailedMutation: true,
      ),
    );

    try {
      final update = await _repository.updateMatchResult(
        gameId: mutation.gameId,
        homeScore: mutation.homeScore,
        awayScore: mutation.awayScore,
        status: mutation.status,
      );

      if (_disposed) {
        return;
      }

      // HTTP is authoritative for the mutation response. Reverb may deliver
      // the same update before or after this call; update_id deduplicates it.
      _applyUpdate(update);

      final latest = state.value;

      if (latest == null) {
        return;
      }

      state = AsyncData(
        latest.copyWith(
          syncStatus: _syncStatusForRealtime(),
          clearUpdatingMatch: true,
          lastConfirmedAt: update.occurredAt,
          clearError: true,
          clearFailedMutation: true,
        ),
      );
    } catch (error) {
      final latest = state.value;

      if (latest != null && !_disposed) {
        state = AsyncData(
          latest.copyWith(
            syncStatus: TournamentSyncStatus.degraded,
            clearUpdatingMatch: true,
            lastError: error,
            failedMutation: mutation,
          ),
        );
      }
    }
  }

  void _setSyncStatus(TournamentSyncStatus syncStatus) {
    final current = state.value;

    if (current == null || _disposed) {
      return;
    }

    state = AsyncData(current.copyWith(syncStatus: syncStatus));
  }

  void _setNonFatalError(Object error) {
    final current = state.value;

    if (current == null || _disposed) {
      return;
    }

    state = AsyncData(current.copyWith(lastError: error));
  }

  void _dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    for (final queued in _mutationQueue) {
      if (!queued.completer.isCompleted) {
        queued.completer.complete();
      }
    }

    _mutationQueue.clear();

    final updateSubscription = _updateSubscription;
    if (updateSubscription != null) {
      unawaited(updateSubscription.cancel());
    }

    final connectionSubscription = _connectionSubscription;
    if (connectionSubscription != null) {
      unawaited(connectionSubscription.cancel());
    }
  }
}

class _QueuedMatchMutation {
  const _QueuedMatchMutation({required this.mutation, required this.completer});

  final FailedMatchMutation mutation;
  final Completer<void> completer;
}
