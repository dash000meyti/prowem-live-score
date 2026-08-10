import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/game.dart';

class GameStatusBadge extends StatelessWidget {
  const GameStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final GameStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      GameStatus.scheduled => (
        label: 'SCHEDULED',
        foreground: AppColors.warning,
        background: AppColors.warning.withValues(alpha: 0.10),
      ),
      GameStatus.inPlay => (
        label: 'LIVE',
        foreground: AppColors.live,
        background: AppColors.live.withValues(alpha: 0.10),
      ),
      GameStatus.finished => (
        label: 'FINAL',
        foreground: AppColors.textSecondary,
        background: AppColors.surfaceElevated,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.foreground.withValues(alpha: 0.22)),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.foreground,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}
