import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/standing.dart';
import '../../domain/team.dart';
import 'team_badge.dart';

class AnimatedStandingsTable extends StatelessWidget {
  const AnimatedStandingsTable({
    super.key,
    required this.standings,
    required this.teamsById,
  });

  final List<Standing> standings;
  final Map<int, Team> teamsById;

  static const double _rowHeight = 56;
  static const double _headerHeight = 38;

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
          const _SectionTitle(),
          const Divider(height: 1),
          const SizedBox(height: _headerHeight, child: _StandingsHeader()),
          SizedBox(
            height: standings.length * _rowHeight,
            child: Stack(
              children: [
                for (final entry in standings.asMap().entries)
                  AnimatedPositioned(
                    key: ValueKey('standing-positioned-${entry.value.teamId}'),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    top: entry.key * _rowHeight,
                    left: 0,
                    right: 0,
                    height: _rowHeight,
                    child: _StandingRow(
                      rowKey: ValueKey('standing-row-${entry.value.teamId}'),
                      standing: entry.value,
                      team: teamsById[entry.value.teamId],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(14, 13, 14, 11),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded, size: 19, color: AppColors.textPrimary),
          SizedBox(width: 9),
          Text(
            'STANDINGS',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingsHeader extends StatelessWidget {
  const _StandingsHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );

    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: style)),
          Expanded(child: Text('TEAM', style: style)),
          SizedBox(
            width: 34,
            child: Text('P', textAlign: TextAlign.center, style: style),
          ),
          SizedBox(
            width: 44,
            child: Text('GD', textAlign: TextAlign.center, style: style),
          ),
          SizedBox(
            width: 38,
            child: Text('PTS', textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.rowKey,
    required this.standing,
    required this.team,
  });

  final Key rowKey;
  final Standing standing;
  final Team? team;

  @override
  Widget build(BuildContext context) {
    final goalDifference = standing.goalDifference;

    return SizedBox(
      key: rowKey,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${standing.position}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    TeamBadge(team: team, size: 28),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        team?.name ?? 'Team ${standing.teamId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${standing.played}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  goalDifference > 0 ? '+$goalDifference' : '$goalDifference',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  '${standing.points}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
