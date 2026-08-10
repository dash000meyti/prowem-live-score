import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/game.dart';
import '../../domain/team.dart';
import 'game_status_badge.dart';
import 'team_badge.dart';

class ResultEditorSubmission {
  const ResultEditorSubmission({
    required this.homeScore,
    required this.awayScore,
    required this.status,
  });

  final int homeScore;
  final int awayScore;
  final GameStatus status;
}

Future<ResultEditorSubmission?> showResultEditorSheet(
  BuildContext context, {
  required Game game,
  required Team? homeTeam,
  required Team? awayTeam,
  bool startBlocked = false,
}) {
  return showModalBottomSheet<ResultEditorSubmission>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return ResultEditorSheet(
        game: game,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        startBlocked: startBlocked,
      );
    },
  );
}

class ResultEditorSheet extends StatefulWidget {
  const ResultEditorSheet({
    super.key,
    required this.game,
    required this.homeTeam,
    required this.awayTeam,
    this.startBlocked = false,
  });

  final Game game;
  final Team? homeTeam;
  final Team? awayTeam;

  /// Presentation guard only.
  ///
  /// The backend remains authoritative and independently enforces that
  /// a team may participate in at most one live match.
  final bool startBlocked;

  @override
  State<ResultEditorSheet> createState() => _ResultEditorSheetState();
}

class _ResultEditorSheetState extends State<ResultEditorSheet> {
  late int _homeScore;
  late int _awayScore;

  @override
  void initState() {
    super.initState();

    _homeScore = widget.game.homeScore ?? 0;
    _awayScore = widget.game.awayScore ?? 0;
  }

  bool get _scheduledStartBlocked {
    return widget.game.status == GameStatus.scheduled && widget.startBlocked;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RESULT EDITOR',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Use for corrections or detailed edits',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GameStatusBadge(status: widget.game.status),
                ],
              ),
              if (_scheduledStartBlocked) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.24),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_clock_outlined,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'One of these teams is already playing another '
                          'live match. Finish that match before starting this one.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _EditorTeam(
                      team: widget.homeTeam,
                      score: _homeScore,
                      onIncrement: () {
                        setState(() => _homeScore++);
                      },
                      onDecrement: _homeScore == 0
                          ? null
                          : () {
                              setState(() => _homeScore--);
                            },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'vs',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _EditorTeam(
                      team: widget.awayTeam,
                      score: _awayScore,
                      onIncrement: () {
                        setState(() => _awayScore++);
                      },
                      onDecrement: _awayScore == 0
                          ? null
                          : () {
                              setState(() => _awayScore--);
                            },
                    ),
                  ),
                ],
              ),
              if (widget.game.status == GameStatus.inPlay) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _complete(GameStatus.finished);
                    },
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Mark match as final'),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _scheduledStartBlocked
                          ? null
                          : () {
                              final status = switch (widget.game.status) {
                                GameStatus.scheduled => GameStatus.inPlay,
                                GameStatus.inPlay => GameStatus.inPlay,
                                GameStatus.finished => GameStatus.finished,
                              };

                              _complete(status);
                            },
                      child: Text(switch (widget.game.status) {
                        GameStatus.scheduled => 'Start match',
                        GameStatus.inPlay => 'Save',
                        GameStatus.finished => 'Update',
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _complete(GameStatus status) {
    Navigator.of(context).pop(
      ResultEditorSubmission(
        homeScore: _homeScore,
        awayScore: _awayScore,
        status: status,
      ),
    );
  }
}

class _EditorTeam extends StatelessWidget {
  const _EditorTeam({
    required this.team,
    required this.score,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Team? team;
  final int score;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamBadge(team: team, size: 46),
        const SizedBox(height: 9),
        Text(
          team?.name ?? 'Team',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 13),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_rounded),
              ),
            ),
            Container(
              width: 44,
              alignment: Alignment.center,
              child: Text(
                '$score',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: onIncrement,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
