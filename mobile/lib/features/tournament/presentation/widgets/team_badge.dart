import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/team.dart';

class TeamBadge extends StatelessWidget {
  const TeamBadge({super.key, required this.team, this.size = 34});

  final Team? team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = team?.name.trim() ?? '?';
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    final logoUrl = team?.logoUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl == null
          ? _InitialFallback(initial: initial, size: size)
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _InitialFallback(initial: initial, size: size);
              },
            ),
    );
  }
}

class _InitialFallback extends StatelessWidget {
  const _InitialFallback({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: size * 0.40,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
