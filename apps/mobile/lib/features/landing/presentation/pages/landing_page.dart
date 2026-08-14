import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/login_controller.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/widgets/prowem_brand.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({required this.loginController, super.key});

  final LoginController loginController;

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(controller: loginController),
      ),
    );
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'One event. One clear flow.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Event Care keeps your team focused before kickoff, during live operations, and after the final whistle.',
                style: TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 20),
              const _FlowStep(
                number: '01',
                title: 'Prepare',
                body: 'Find readiness blockers and take the next safe action.',
                color: AppColors.lime,
              ),
              const _FlowStep(
                number: '02',
                title: 'Monitor',
                body: 'See live matches and urgent operational issues first.',
                color: AppColors.cyan,
              ),
              const _FlowStep(
                number: '03',
                title: 'Resolve',
                body:
                    'Your team handles operations; PROWEM owns technical support.',
                color: AppColors.purple,
              ),
              const _FlowStep(
                number: '04',
                title: 'Improve',
                body:
                    'Review the Event Care report and act on recommendations.',
                color: AppColors.coral,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openLogin(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Take Control'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.height < 720 || media.size.width < 360;
    final backgroundCacheWidth = (media.size.width * media.devicePixelRatio)
        .round()
        .clamp(720, 1440)
        .toInt();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/event-care-stadium.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: backgroundCacheWidth,
            filterQuality: FilterQuality.low,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x4D000000),
                  Color(0xB305070A),
                  AppColors.background,
                ],
                stops: [0, .42, .76],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(.7, -.2),
                radius: .85,
                colors: [
                  AppColors.lime.withValues(alpha: .16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(18, compact ? 14 : 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: ProwemBrand(compact: true, horizontal: true),
                      ),
                      TextButton(
                        onPressed: () => _openLogin(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          side: const BorderSide(color: AppColors.border),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 38 : 54),
                  const Text(
                    'PROWEM EVENT GUARDIAN',
                    style: TextStyle(
                      color: AppColors.lime,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Everything at Your\n'),
                        TextSpan(
                          text: 'Command',
                          style: TextStyle(
                            color: AppColors.lime,
                            shadows: [
                              Shadow(
                                color: AppColors.lime.withValues(alpha: .32),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 40 : 46,
                      height: .94,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Prepare, manage, and improve every football event from one operational command space.',
                    style: TextStyle(
                      color: Color(0xFFD1D6DE),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: compact ? 22 : 30),
                  const _CommandPreview(),
                  const SizedBox(height: 26),
                  FilledButton.icon(
                    onPressed: () => _openLogin(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(58),
                      backgroundColor: AppColors.lime,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Take Control'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _showHowItWorks(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text('How It Works'),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'BUILT FOR MATCH DAY',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(
                        child: _PromiseCard(
                          icon: Icons.task_alt_rounded,
                          title: 'Prepare',
                          detail: 'Clear blockers',
                          color: AppColors.lime,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _PromiseCard(
                          icon: Icons.sensors_rounded,
                          title: 'Monitor',
                          detail: 'Stay in control',
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(
                        child: _PromiseCard(
                          icon: Icons.support_agent_rounded,
                          title: 'Resolve',
                          detail: 'Get support',
                          color: AppColors.purple,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _PromiseCard(
                          icon: Icons.trending_up_rounded,
                          title: 'Improve',
                          detail: 'Learn from reports',
                          color: AppColors.coral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'YOUR EVENT IS OUR EVENT.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandPreview extends StatelessWidget {
  const _CommandPreview();

  @override
  Widget build(BuildContext context) => Container(
        height: 255,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.lime.withValues(alpha: .35)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xE61A2028), Color(0xF0080B0F)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.lime.withValues(alpha: .1),
              blurRadius: 36,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.lime,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ALPINE YOUTH CUP 2026',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
                const _TinyBadge(label: 'READY', color: AppColors.lime),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .045),
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EVENT READINESS',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '100%',
                            style: TextStyle(
                              color: AppColors.lime,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: const LinearProgressIndicator(
                              value: 1,
                              minHeight: 5,
                              backgroundColor: Color(0x1FFFFFFF),
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.lime),
                            ),
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            'Ready for kickoff',
                            style: TextStyle(
                              color: Color(0xFFD5DBE3),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        const Expanded(
                          child: _PreviewStatus(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'All clear',
                            detail: 'No blockers live',
                            color: AppColors.cyan,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _PreviewStatus(
                            icon: Icons.support_agent_rounded,
                            title: 'PROWEM ready',
                            detail: 'Support on standby',
                            color: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.sensors_rounded, size: 16, color: AppColors.lime),
                SizedBox(width: 7),
                Text(
                  'Live operational truth across every device',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
}

class _PreviewStatus extends StatelessWidget {
  const _PreviewStatus({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          border: Border.all(color: color.withValues(alpha: .24)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          border: Border.all(color: color.withValues(alpha: .5)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _PromiseCard extends StatelessWidget {
  const _PromiseCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xB312161E),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      );
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.number,
    required this.title,
    required this.body,
    required this.color,
  });

  final String number;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                border: Border.all(color: color.withValues(alpha: .35)),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                number,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
