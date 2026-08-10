import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/game.dart';
import '../../domain/team.dart';
import 'game_status_badge.dart';
import 'team_badge.dart';

typedef MatchResultUpdateCallback =
    Future<void> Function({
      required int gameId,
      required int homeScore,
      required int awayScore,
      required GameStatus status,
    });

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.game,
    required this.homeTeam,
    required this.awayTeam,
    required this.isBusy,
    required this.isUpdating,
    required this.onUpdateResult,
    this.lastConfirmedAt,
    this.onEditResult,
  });

  final Game game;
  final Team? homeTeam;
  final Team? awayTeam;
  final bool isBusy;
  final bool isUpdating;
  final DateTime? lastConfirmedAt;
  final MatchResultUpdateCallback onUpdateResult;
  final VoidCallback? onEditResult;

  @override
  Widget build(BuildContext context) {
    final homeScore = game.homeScore ?? 0;
    final awayScore = game.awayScore ?? 0;

    final title = switch (game.status) {
      GameStatus.scheduled => 'NEXT MATCH',
      GameStatus.inPlay => 'LIVE MATCH',
      GameStatus.finished => 'LATEST RESULT',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: game.status == GameStatus.inPlay
                      ? AppColors.live
                      : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (isUpdating)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              GameStatusBadge(status: game.status),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _TeamScore(team: homeTeam, score: homeScore),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '–',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: _TeamScore(team: awayTeam, score: awayScore),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (game.status == GameStatus.inPlay) ...[
            Row(
              children: [
                Expanded(
                  child: _GoalButton(
                    enabled: !isBusy,
                    onPressed: () {
                      _submit(
                        homeScore: homeScore + 1,
                        awayScore: awayScore,
                        status: GameStatus.inPlay,
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _GoalButton(
                    enabled: !isBusy,
                    onPressed: () {
                      _submit(
                        homeScore: homeScore,
                        awayScore: awayScore + 1,
                        status: GameStatus.inPlay,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onEditResult,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit / correct result'),
            ),
          ] else if (game.status == GameStatus.scheduled) ...[
            FilledButton.icon(
              onPressed: isBusy
                  ? null
                  : () {
                      _submit(
                        homeScore: homeScore,
                        awayScore: awayScore,
                        status: GameStatus.inPlay,
                      );
                    },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start match'),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: isBusy ? null : onEditResult,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Correct result'),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _lastUpdateLabel(lastConfirmedAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit({
    required int homeScore,
    required int awayScore,
    required GameStatus status,
  }) {
    onUpdateResult(
      gameId: game.id,
      homeScore: homeScore,
      awayScore: awayScore,
      status: status,
    );
  }
}

class _TeamScore extends StatelessWidget {
  const _TeamScore({required this.team, required this.score});

  final Team? team;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamBadge(team: team, size: 52),
        const SizedBox(height: 10),
        Text(
          '$score',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 48,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          team?.name ?? 'Team',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GoalButton extends StatelessWidget {
  const _GoalButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.sports_soccer_rounded),
        label: const Text('+ GOAL'),
      ),
    );
  }
}

String _lastUpdateLabel(DateTime? value) {
  if (value == null) return 'Waiting for confirmation';

  final local = value.toLocal();
  final difference = DateTime.now().difference(local);

  if (!difference.isNegative && difference < const Duration(minutes: 1)) {
    return 'Last update: just now';
  }

  if (!difference.isNegative && difference < const Duration(hours: 1)) {
    return 'Last update: ${difference.inMinutes}m ago';
  }

  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return 'Last update: $hour:$minute';
}
