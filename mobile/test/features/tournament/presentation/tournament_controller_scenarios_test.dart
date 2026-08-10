import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_realtime_client.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';
import 'package:prowem_live_score/features/tournament/domain/tournament_snapshot.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_controller.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_providers.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_state.dart';

import '../../../support/tournament_scenario_support.dart';

void main() {
  group('TournamentController scenario regressions', () {
    test(
      'REGRESSION: rapid same-match score requests preserve the latest requested score',
      () async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_twoLiveMatchesSnapshot()],
        )..holdMutations = true;

        addTearDown(repository.dispose);

        final container = ProviderContainer.test(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
          ],
        );

        await container.read(tournamentControllerProvider.future);
        await flushScenarioEvents();

        final controller = container.read(
          tournamentControllerProvider.notifier,
        );

        final first = controller.updateMatchResult(
          gameId: 1,
          homeScore: 1,
          awayScore: 0,
          status: GameStatus.inPlay,
        );

        await flushScenarioEvents();

        expect(repository.mutationCalls, hasLength(1));

        final second = controller.updateMatchResult(
          gameId: 1,
          homeScore: 2,
          awayScore: 0,
          status: GameStatus.inPlay,
        );

        repository.completeNextMutation(
          scenarioUpdate(
            updateId: 'rapid-1',
            gameId: 1,
            round: 1,
            homeTeamId: 1,
            awayTeamId: 4,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus.inPlay,
            standings: standingsAfterJuventusWin(homeScore: 1, awayScore: 0),
          ),
        );

        await first;
        await flushScenarioEvents();

        // Desired behavior:
        // the second user intent must not disappear while request #1 is
        // pending. The controller should eventually submit the requested 2-0.
        expect(
          repository.mutationCalls,
          hasLength(2),
          reason:
              'The second same-match score intent was dropped while the first '
              'request was pending.',
        );

        if (repository.pendingMutationCount == 1) {
          repository.completeNextMutation(
            scenarioUpdate(
              updateId: 'rapid-2',
              gameId: 1,
              round: 1,
              homeTeamId: 1,
              awayTeamId: 4,
              homeScore: 2,
              awayScore: 0,
              status: GameStatus.inPlay,
              standings: standingsAfterJuventusWin(homeScore: 2, awayScore: 0),
            ),
          );
        }

        await second;
        await flushScenarioEvents();

        final state = container.read(tournamentControllerProvider).requireValue;

        final game = state.snapshot.games.firstWhere((game) => game.id == 1);

        expect(game.homeScore, 2);
        expect(game.awayScore, 0);
      },
    );

    test(
      'two different live matches submitted while first request is pending are both preserved',
      () async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_twoLiveMatchesSnapshot()],
        )..holdMutations = true;

        addTearDown(repository.dispose);

        final container = ProviderContainer.test(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
          ],
        );

        await container.read(tournamentControllerProvider.future);
        await flushScenarioEvents();

        final controller = container.read(
          tournamentControllerProvider.notifier,
        );

        final first = controller.updateMatchResult(
          gameId: 1,
          homeScore: 1,
          awayScore: 0,
          status: GameStatus.inPlay,
        );

        await flushScenarioEvents();

        final second = controller.updateMatchResult(
          gameId: 2,
          homeScore: 1,
          awayScore: 0,
          status: GameStatus.inPlay,
        );

        await flushScenarioEvents();

        // Controller serializes outbound PATCH calls, so the second mutation
        // is queued locally until the first server response arrives.
        expect(repository.mutationCalls, hasLength(1));
        expect(repository.mutationCalls.single.gameId, 1);

        repository.completeNextMutation(
          scenarioUpdate(
            updateId: 'different-a',
            gameId: 1,
            round: 1,
            homeTeamId: 1,
            awayTeamId: 4,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus.inPlay,
            standings: standingsAfterJuventusWin(homeScore: 1, awayScore: 0),
          ),
        );

        await first;
        await flushScenarioEvents();

        expect(repository.mutationCalls, hasLength(2));
        expect(repository.mutationCalls.last.gameId, 2);

        repository.completeNextMutation(
          scenarioUpdate(
            updateId: 'different-b',
            gameId: 2,
            round: 1,
            homeTeamId: 2,
            awayTeamId: 3,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus.inPlay,
            standings: standingsAfterInterWin(homeScore: 1, awayScore: 0),
          ),
        );

        await second;
        await flushScenarioEvents();

        final state = container.read(tournamentControllerProvider).requireValue;

        final firstGame = state.snapshot.games.firstWhere(
          (game) => game.id == 1,
        );
        final secondGame = state.snapshot.games.firstWhere(
          (game) => game.id == 2,
        );

        expect(firstGame.homeScore, 1);
        expect(secondGame.homeScore, 1);
      },
    );

    test(
      'live correction keeps match in play and applies corrected standings',
      () async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_liveCorrectionSnapshot()],
        );

        repository.responseFactory = (call) {
          return scenarioUpdate(
            updateId: 'live-correction',
            gameId: 2,
            round: 1,
            homeTeamId: 3,
            awayTeamId: 2,
            homeScore: call.homeScore,
            awayScore: call.awayScore,
            status: call.status,
            standings: [
              standingJson(position: 1, teamId: 1),
              standingJson(
                position: 2,
                teamId: 2,
                played: 1,
                drawn: 1,
                goalsFor: 1,
                goalsAgainst: 1,
                points: 1,
              ),
              standingJson(
                position: 3,
                teamId: 3,
                played: 1,
                drawn: 1,
                goalsFor: 1,
                goalsAgainst: 1,
                points: 1,
              ),
              standingJson(position: 4, teamId: 4),
            ],
          );
        };

        addTearDown(repository.dispose);

        final container = ProviderContainer.test(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
          ],
        );

        await container.read(tournamentControllerProvider.future);
        await flushScenarioEvents();

        await container
            .read(tournamentControllerProvider.notifier)
            .updateMatchResult(
              gameId: 2,
              homeScore: 1,
              awayScore: 1,
              status: GameStatus.inPlay,
            );

        final state = container.read(tournamentControllerProvider).requireValue;

        final game = state.snapshot.games.firstWhere((game) => game.id == 2);

        expect(game.homeScore, 1);
        expect(game.awayScore, 1);
        expect(game.status, GameStatus.inPlay);

        final inter = state.snapshot.standings.firstWhere(
          (standing) => standing.teamId == 2,
        );

        final milan = state.snapshot.standings.firstWhere(
          (standing) => standing.teamId == 3,
        );

        expect(inter.points, 1);
        expect(milan.points, 1);
      },
    );

    test(
      'finished correction remains finished and applies corrected standings',
      () async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_finishedCorrectionSnapshot()],
        );

        repository.responseFactory = (call) {
          return scenarioUpdate(
            updateId: 'finished-correction',
            gameId: 1,
            round: 1,
            homeTeamId: 1,
            awayTeamId: 4,
            homeScore: call.homeScore,
            awayScore: call.awayScore,
            status: call.status,
            standings: [
              standingJson(
                position: 1,
                teamId: 1,
                played: 1,
                drawn: 1,
                goalsFor: 1,
                goalsAgainst: 1,
                points: 1,
              ),
              standingJson(position: 2, teamId: 2),
              standingJson(position: 3, teamId: 3),
              standingJson(
                position: 4,
                teamId: 4,
                played: 1,
                drawn: 1,
                goalsFor: 1,
                goalsAgainst: 1,
                points: 1,
              ),
            ],
          );
        };

        addTearDown(repository.dispose);

        final container = ProviderContainer.test(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
          ],
        );

        await container.read(tournamentControllerProvider.future);
        await flushScenarioEvents();

        await container
            .read(tournamentControllerProvider.notifier)
            .updateMatchResult(
              gameId: 1,
              homeScore: 1,
              awayScore: 1,
              status: GameStatus.finished,
            );

        final state = container.read(tournamentControllerProvider).requireValue;

        final game = state.snapshot.games.firstWhere((game) => game.id == 1);

        expect(game.homeScore, 1);
        expect(game.awayScore, 1);
        expect(game.status, GameStatus.finished);
      },
    );

    test(
      'backend failure preserves confirmed snapshot and retry applies failed mutation',
      () async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_twoLiveMatchesSnapshot()],
        );

        repository.mutationError = Exception('backend unavailable');

        addTearDown(repository.dispose);

        final container = ProviderContainer.test(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
          ],
        );

        await container.read(tournamentControllerProvider.future);
        await flushScenarioEvents();

        await container
            .read(tournamentControllerProvider.notifier)
            .updateMatchResult(
              gameId: 1,
              homeScore: 1,
              awayScore: 0,
              status: GameStatus.inPlay,
            );

        var state = container.read(tournamentControllerProvider).requireValue;

        final failedGame = state.snapshot.games.firstWhere(
          (game) => game.id == 1,
        );

        expect(failedGame.homeScore, 0);
        expect(state.syncStatus, TournamentSyncStatus.degraded);
        expect(state.hasFailedMutation, isTrue);

        repository.mutationError = null;
        repository.responseFactory = (call) {
          return scenarioUpdate(
            updateId: 'retry-success',
            gameId: 1,
            round: 1,
            homeTeamId: 1,
            awayTeamId: 4,
            homeScore: call.homeScore,
            awayScore: call.awayScore,
            status: call.status,
            standings: standingsAfterJuventusWin(
              homeScore: call.homeScore,
              awayScore: call.awayScore,
            ),
          );
        };

        await container
            .read(tournamentControllerProvider.notifier)
            .retryLastFailure();

        await flushScenarioEvents();

        state = container.read(tournamentControllerProvider).requireValue;

        final retriedGame = state.snapshot.games.firstWhere(
          (game) => game.id == 1,
        );

        expect(retriedGame.homeScore, 1);
        expect(state.hasFailedMutation, isFalse);
        expect(state.syncStatus, TournamentSyncStatus.synced);
      },
    );

    test(
      'reverb disconnect keeps REST state and reconnect triggers REST resync',
      () async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_twoLiveMatchesSnapshot(), _resyncedSnapshot()],
        );

        addTearDown(repository.dispose);

        final container = ProviderContainer.test(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
          ],
        );

        await container.read(tournamentControllerProvider.future);
        await flushScenarioEvents();

        repository.emitStatus(RealtimeConnectionStatus.reconnecting);

        await flushScenarioEvents();

        var state = container.read(tournamentControllerProvider).requireValue;

        expect(state.syncStatus, TournamentSyncStatus.reconnecting);

        // REST snapshot must still be available while the socket is down.
        expect(state.snapshot.games, hasLength(2));

        repository.emitStatus(RealtimeConnectionStatus.connected);

        await flushScenarioEvents(5);

        state = container.read(tournamentControllerProvider).requireValue;

        final game = state.snapshot.games.firstWhere((game) => game.id == 1);

        expect(repository.fetchCallCount, 2);
        expect(game.homeScore, 3);
        expect(game.awayScore, 1);
        expect(state.syncStatus, TournamentSyncStatus.synced);
      },
    );

    test(
      'external realtime update is applied without a REST refresh',
      () async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_twoLiveMatchesSnapshot()],
        );

        addTearDown(repository.dispose);

        final container = ProviderContainer.test(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
          ],
        );

        await container.read(tournamentControllerProvider.future);
        await flushScenarioEvents();

        repository.emitUpdate(
          scenarioUpdate(
            updateId: 'external-score',
            gameId: 2,
            round: 1,
            homeTeamId: 2,
            awayTeamId: 3,
            homeScore: 2,
            awayScore: 0,
            status: GameStatus.inPlay,
            standings: standingsAfterInterWin(homeScore: 2, awayScore: 0),
          ),
        );

        await flushScenarioEvents();

        final state = container.read(tournamentControllerProvider).requireValue;

        final game = state.snapshot.games.firstWhere((game) => game.id == 2);

        expect(repository.fetchCallCount, 1);
        expect(game.homeScore, 2);
        expect(game.awayScore, 0);
      },
    );
  });
}

TournamentSnapshot _twoLiveMatchesSnapshot() {
  return scenarioSnapshot(
    matches: [
      matchJson(
        id: 1,
        round: 1,
        homeTeamId: 1,
        awayTeamId: 4,
        homeScore: 0,
        awayScore: 0,
        status: GameStatus.inPlay,
      ),
      matchJson(
        id: 2,
        round: 1,
        homeTeamId: 2,
        awayTeamId: 3,
        homeScore: 0,
        awayScore: 0,
        status: GameStatus.inPlay,
      ),
    ],
    standings: neutralStandings(),
  );
}

TournamentSnapshot _liveCorrectionSnapshot() {
  return scenarioSnapshot(
    matches: [
      matchJson(
        id: 2,
        round: 1,
        homeTeamId: 3,
        awayTeamId: 2,
        homeScore: 2,
        awayScore: 1,
        status: GameStatus.inPlay,
      ),
    ],
    standings: [
      standingJson(
        position: 1,
        teamId: 3,
        played: 1,
        won: 1,
        goalsFor: 2,
        goalsAgainst: 1,
        goalDifference: 1,
        points: 3,
      ),
      standingJson(position: 2, teamId: 1),
      standingJson(position: 3, teamId: 4),
      standingJson(
        position: 4,
        teamId: 2,
        played: 1,
        lost: 1,
        goalsFor: 1,
        goalsAgainst: 2,
        goalDifference: -1,
      ),
    ],
  );
}

TournamentSnapshot _finishedCorrectionSnapshot() {
  return scenarioSnapshot(
    matches: [
      matchJson(
        id: 1,
        round: 1,
        homeTeamId: 1,
        awayTeamId: 4,
        homeScore: 2,
        awayScore: 0,
        status: GameStatus.finished,
      ),
    ],
    standings: standingsAfterJuventusWin(homeScore: 2, awayScore: 0),
  );
}

TournamentSnapshot _resyncedSnapshot() {
  return scenarioSnapshot(
    matches: [
      matchJson(
        id: 1,
        round: 1,
        homeTeamId: 1,
        awayTeamId: 4,
        homeScore: 3,
        awayScore: 1,
        status: GameStatus.inPlay,
      ),
      matchJson(
        id: 2,
        round: 1,
        homeTeamId: 2,
        awayTeamId: 3,
        homeScore: 0,
        awayScore: 0,
        status: GameStatus.inPlay,
      ),
    ],
    standings: standingsAfterJuventusWin(homeScore: 3, awayScore: 1),
  );
}
