import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/game.dart';
import '../../domain/team.dart';
import 'game_status_badge.dart';
import 'team_badge.dart';

class TournamentMatchList extends StatelessWidget {
  const TournamentMatchList({
    super.key,
    required this.games,
    required this.teamsById,
    required this.lastConfirmedAt,
    required this.onMatchTap,
  });

  final List<Game> games;
  final Map<int, Team> teamsById;
  final DateTime lastConfirmedAt;
  final ValueChanged<Game> onMatchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 13, 14, 11),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 19,
                  color: AppColors.textPrimary,
                ),
                SizedBox(width: 9),
                Text(
                  'MATCHES',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var index = 0; index < games.length; index++) ...[
            _MatchRow(
              game: games[index],
              homeTeam: teamsById[games[index].homeTeamId],
              awayTeam: teamsById[games[index].awayTeamId],
              onTap: () => onMatchTap(games[index]),
            ),
            if (index != games.length - 1)
              const Divider(height: 1, indent: 14, endIndent: 14),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                const Text(
                  'All times local',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.sync_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  _updatedLabel(lastConfirmedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.game,
    required this.homeTeam,
    required this.awayTeam,
    required this.onTap,
  });

  final Game game;
  final Team? homeTeam;
  final Team? awayTeam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final homeScore = game.homeScore ?? 0;
    final awayScore = game.awayScore ?? 0;

    final score = switch (game.status) {
      GameStatus.scheduled => 'vs',
      GameStatus.inPlay || GameStatus.finished => '$homeScore - $awayScore',
    };

    final indicatorColor = switch (game.status) {
      GameStatus.scheduled => AppColors.warning,
      GameStatus.inPlay => AppColors.live,
      GameStatus.finished => AppColors.textMuted,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: indicatorColor,
                  ),
                ),
                const SizedBox(width: 8),
                TeamBadge(team: homeTeam, size: 28),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    homeTeam?.name ?? 'Home',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    score,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    awayTeam?.name ?? 'Away',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                TeamBadge(team: awayTeam, size: 28),
                const SizedBox(width: 8),
                GameStatusBadge(status: game.status, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _updatedLabel(DateTime value) {
  final local = value.toLocal();
  final difference = DateTime.now().difference(local);

  if (!difference.isNegative && difference < const Duration(minutes: 1)) {
    return 'Updated just now';
  }

  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return 'Updated $hour:$minute';
}
