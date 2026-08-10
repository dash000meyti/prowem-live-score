import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../tournament_state.dart';

class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({super.key, required this.status});

  final TournamentSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      TournamentSyncStatus.synced => (
        label: 'SYNCED',
        color: AppColors.success,
        icon: Icons.wifi_rounded,
      ),
      TournamentSyncStatus.connecting ||
      TournamentSyncStatus.syncing ||
      TournamentSyncStatus.resyncing => (
        label: 'SYNCING...',
        color: AppColors.warning,
        icon: Icons.sync_rounded,
      ),
      TournamentSyncStatus.reconnecting => (
        label: 'RECONNECTING...',
        color: AppColors.info,
        icon: Icons.sync_rounded,
      ),
      TournamentSyncStatus.degraded => (
        label: 'SYNC FAILED',
        color: AppColors.danger,
        icon: Icons.warning_amber_rounded,
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.color,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          Icon(config.icon, size: 17, color: config.color),
        ],
      ),
    );
  }
}
