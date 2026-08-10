import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../domain/game.dart';
import '../domain/team.dart';
import 'tournament_controller.dart';
import 'tournament_state.dart';
import 'widgets/animated_standings_table.dart';
import 'widgets/connection_status_chip.dart';
import 'widgets/match_card.dart';
import 'widgets/match_list.dart';
import 'widgets/result_editor_sheet.dart';

class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasData = ref.watch(
      tournamentControllerProvider.select(
        (asyncState) => asyncState.value != null,
      ),
    );

    final hasInitialError = ref.watch(
      tournamentControllerProvider.select(
        (asyncState) => asyncState.value == null && asyncState.hasError,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: switch ((hasData, hasInitialError)) {
        (true, _) => const _TournamentContent(),
        (false, true) => _ErrorScreen(
          onRetry: () {
            ref.invalidate(tournamentControllerProvider);
          },
        ),
        _ => const _LoadingScreen(),
      },
    );
  }
}

class _TournamentContent extends ConsumerWidget {
  const _TournamentContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () {
            return ref
                .read(tournamentControllerProvider.notifier)
                .refreshSnapshot();
          },
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            children: const [
              _HeaderConnector(),
              _SyncFailureConnector(),
              _FocusMatchesConnector(),
              SizedBox(height: 10),
              _StandingsConnector(),
              SizedBox(height: 10),
              _MatchListConnector(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderConnector extends ConsumerWidget {
  const _HeaderConnector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(
      tournamentControllerProvider.select(
        (asyncState) =>
            asyncState.value?.syncStatus ?? TournamentSyncStatus.connecting,
      ),
    );

    return _Header(syncStatus: syncStatus);
  }
}

class _SyncFailureConnector extends ConsumerWidget {
  const _SyncFailureConnector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failureState = ref.watch(
      tournamentControllerProvider.select((asyncState) {
        final value = asyncState.value;

        return (
          degraded: value?.syncStatus == TournamentSyncStatus.degraded,
          hasFailedMutation: value?.hasFailedMutation ?? false,
        );
      }),
    );

    if (!failureState.degraded) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _SyncFailureBanner(
        hasFailedMutation: failureState.hasFailedMutation,
        onRetry: () {
          return ref
              .read(tournamentControllerProvider.notifier)
              .retryLastFailure();
        },
      ),
    );
  }
}

class _FocusMatchesConnector extends ConsumerWidget {
  const _FocusMatchesConnector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuild this section when match identity/status changes.
    //
    // A score-only update keeps the same signature, so updating match B does
    // not rebuild match A's quick-score card.
    ref.watch(
      tournamentControllerProvider.select((asyncState) {
        final games = asyncState.value?.snapshot.games;

        if (games == null) {
          return '';
        }

        return games
            .map((game) => '${game.id}:${game.status.apiValue}')
            .join('|');
      }),
    );

    final state = ref.read(tournamentControllerProvider).value;

    if (state == null) {
      return const SizedBox.shrink();
    }

    final games = List<Game>.of(state.snapshot.games)
      ..sort((a, b) {
        final roundComparison = a.roundNumber.compareTo(b.roundNumber);

        if (roundComparison != 0) {
          return roundComparison;
        }

        return a.id.compareTo(b.id);
      });

    final liveGames = games
        .where((game) => game.status == GameStatus.inPlay)
        .toList(growable: false);

    final focusGames = _selectFocusGames(games: games, liveGames: liveGames);

    if (focusGames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          for (var index = 0; index < focusGames.length; index++) ...[
            _MatchCardConnector(
              key: ValueKey('featured-match-${focusGames[index].id}'),
              gameId: focusGames[index].id,
            ),
            if (index != focusGames.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MatchCardConnector extends ConsumerWidget {
  const _MatchCardConnector({super.key, required this.gameId});

  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(
      tournamentControllerProvider.select((asyncState) {
        final games = asyncState.value?.snapshot.games;

        if (games == null) {
          return null;
        }

        for (final game in games) {
          if (game.id == gameId) {
            return game;
          }
        }

        return null;
      }),
    );

    final isUpdating = ref.watch(
      tournamentControllerProvider.select(
        (asyncState) => asyncState.value?.updatingMatchId == gameId,
      ),
    );

    final confirmedAt = ref.watch(
      tournamentControllerProvider.select(
        (asyncState) => asyncState.value?.confirmedAtForMatch(gameId),
      ),
    );

    if (game == null) {
      return const SizedBox.shrink();
    }

    final current = ref.read(tournamentControllerProvider).value;

    if (current == null) {
      return const SizedBox.shrink();
    }

    final teamsById = <int, Team>{
      for (final team in current.snapshot.teams) team.id: team,
    };

    return MatchCard(
      game: game,
      homeTeam: teamsById[game.homeTeamId],
      awayTeam: teamsById[game.awayTeamId],

      // Only the card actually being submitted enters a busy visual state.
      // Another live match stays completely stable.
      isBusy: isUpdating,
      isUpdating: isUpdating,
      lastConfirmedAt: confirmedAt,
      onUpdateResult:
          ({
            required int gameId,
            required int homeScore,
            required int awayScore,
            required GameStatus status,
          }) {
            return ref
                .read(tournamentControllerProvider.notifier)
                .updateMatchResult(
                  gameId: gameId,
                  homeScore: homeScore,
                  awayScore: awayScore,
                  status: status,
                );
          },
      onEditResult: () {
        _openResultEditor(
          context,
          ref,
          game: game,
          homeTeam: teamsById[game.homeTeamId],
          awayTeam: teamsById[game.awayTeamId],
        );
      },
    );
  }
}

class _StandingsConnector extends ConsumerWidget {
  const _StandingsConnector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(
      tournamentControllerProvider.select(
        (asyncState) => asyncState.value?.snapshot.standings,
      ),
    );

    if (standings == null) {
      return const SizedBox.shrink();
    }

    final current = ref.read(tournamentControllerProvider).value;

    if (current == null) {
      return const SizedBox.shrink();
    }

    final teamsById = <int, Team>{
      for (final team in current.snapshot.teams) team.id: team,
    };

    return AnimatedStandingsTable(standings: standings, teamsById: teamsById);
  }
}

class _MatchListConnector extends ConsumerWidget {
  const _MatchListConnector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(
      tournamentControllerProvider.select(
        (asyncState) => asyncState.value?.snapshot.games,
      ),
    );

    final lastConfirmedAt = ref.watch(
      tournamentControllerProvider.select(
        (asyncState) => asyncState.value?.lastConfirmedAt,
      ),
    );

    if (games == null || lastConfirmedAt == null) {
      return const SizedBox.shrink();
    }

    final current = ref.read(tournamentControllerProvider).value;

    if (current == null) {
      return const SizedBox.shrink();
    }

    final sortedGames = List<Game>.of(games)
      ..sort((a, b) {
        final roundComparison = a.roundNumber.compareTo(b.roundNumber);

        if (roundComparison != 0) {
          return roundComparison;
        }

        return a.id.compareTo(b.id);
      });

    final teamsById = <int, Team>{
      for (final team in current.snapshot.teams) team.id: team,
    };

    return TournamentMatchList(
      games: sortedGames,
      teamsById: teamsById,
      lastConfirmedAt: lastConfirmedAt,
      onMatchTap: (game) {
        _openResultEditor(
          context,
          ref,
          game: game,
          homeTeam: teamsById[game.homeTeamId],
          awayTeam: teamsById[game.awayTeamId],
        );
      },
    );
  }
}

Future<void> _openResultEditor(
  BuildContext context,
  WidgetRef ref, {
  required Game game,
  required Team? homeTeam,
  required Team? awayTeam,
}) async {
  final current = ref.read(tournamentControllerProvider).value;

  if (current == null) {
    return;
  }

  final liveTeamIds = <int>{
    for (final liveGame in current.snapshot.games)
      if (liveGame.status == GameStatus.inPlay) ...[
        liveGame.homeTeamId,
        liveGame.awayTeamId,
      ],
  };

  final startBlocked =
      game.status == GameStatus.scheduled &&
      (liveTeamIds.contains(game.homeTeamId) ||
          liveTeamIds.contains(game.awayTeamId));

  final result = await showResultEditorSheet(
    context,
    game: game,
    homeTeam: homeTeam,
    awayTeam: awayTeam,
    startBlocked: startBlocked,
  );

  if (result == null || !context.mounted) {
    return;
  }

  await ref
      .read(tournamentControllerProvider.notifier)
      .updateMatchResult(
        gameId: game.id,
        homeScore: result.homeScore,
        awayScore: result.awayScore,
        status: result.status,
      );
}

List<Game> _selectFocusGames({
  required List<Game> games,
  required List<Game> liveGames,
}) {
  if (liveGames.isNotEmpty) {
    return liveGames;
  }

  for (final game in games) {
    if (game.status == GameStatus.scheduled) {
      return [game];
    }
  }

  if (games.isNotEmpty) {
    return [games.last];
  }

  return const [];
}

class _Header extends StatelessWidget {
  const _Header({required this.syncStatus});

  final TournamentSyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'LIVE TOURNAMENT',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ConnectionStatusChip(status: syncStatus),
        ],
      ),
    );
  }
}

class _SyncFailureBanner extends StatelessWidget {
  const _SyncFailureBanner({
    required this.onRetry,
    required this.hasFailedMutation,
  });

  final Future<void> Function() onRetry;
  final bool hasFailedMutation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              hasFailedMutation
                  ? 'Could not save the last change. '
                        'The last confirmed state is still shown.'
                  : 'Could not synchronize the latest tournament state.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onRetry();
            },
            child: const Text(
              'RETRY',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.large),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 46,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Could not load tournament',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Check the connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
