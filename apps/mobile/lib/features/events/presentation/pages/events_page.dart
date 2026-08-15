import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../domain/entities/event_card.dart';
import '../controllers/events_controller.dart';
import '../../../auth/presentation/widgets/prowem_brand.dart';
import '../../../event_workspace/data/event_workspace_repository.dart';
import '../../../event_workspace/presentation/pages/event_workspace_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({
    required this.controller,
    required this.workspaceRepository,
    required this.user,
    required this.onLogout,
    super.key,
  });
  final EventsController controller;
  final EventWorkspaceRepository workspaceRepository;
  final AuthUser user;
  final Future<void> Function() onLogout;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  void _goHome() => Navigator.of(context).popUntil((route) => route.isFirst);

  Future<void> _logout() async {
    await widget.onLogout();
    if (!mounted) return;
    _goHome();
  }

  void _showAccount() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 22),
              _AccountIdentity(user: widget.user, centered: true),
              const SizedBox(height: 20),
              _AccountAction(
                icon: Icons.home_outlined,
                title: 'Back to home',
                subtitle: 'Leave the Organizer workspace',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _goHome();
                },
              ),
              const SizedBox(height: 8),
              _AccountAction(
                icon: Icons.logout_rounded,
                title: 'Log out',
                subtitle: 'Clear this session from the device',
                color: AppColors.danger,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _Header(
                        controller: widget.controller,
                        repository: widget.workspaceRepository,
                        user: widget.user,
                        openAccount: _showAccount)),
                if (widget.controller.isLoading)
                  const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()))
                else if (widget.controller.errorMessage case final error?)
                  SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EventsError(
                          message: error,
                          sessionExpired: widget.controller.sessionExpired,
                          retry: widget.controller.load,
                          signIn: () async {
                            await widget.onLogout();
                            if (!context.mounted) return;
                            _goHome();
                          }))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                    sliver: SliverList.list(
                        children: _groupedCards(widget.controller.events)),
                  ),
              ],
            ),
          ),
        ),
      );

  List<Widget> _groupedCards(List<EventCard> events) {
    final groups = <String, List<EventCard>>{};
    for (final event in events) {
      (groups[event.status] ??= []).add(event);
    }
    return ['live', 'preparing', 'ready', 'completed', 'cancelled']
        .expand((status) {
      final items = groups[status] ?? const [];
      if (items.isEmpty) return <Widget>[];
      final sectionTone =
          status == 'live' && items.any((event) => event.criticalIncidents > 0)
              ? AppColors.danger
              : _tone(status);
      return <Widget>[
        Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 7),
            child: Text(
                status == 'preparing' ? 'UPCOMING' : status.toUpperCase(),
                style: TextStyle(
                    color: sectionTone,
                    fontWeight: FontWeight.w800,
                    fontSize: 16))),
        ...items.map((event) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EventCardView(
                event: event,
                workspaceRepository: widget.workspaceRepository,
                onChanged: widget.controller.load))),
      ];
    }).toList();
  }
}

class _EventsError extends StatelessWidget {
  const _EventsError({
    required this.message,
    required this.sessionExpired,
    required this.retry,
    required this.signIn,
  });

  final String message;
  final bool sessionExpired;
  final VoidCallback retry;
  final VoidCallback signIn;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(sessionExpired ? Icons.lock_clock : Icons.cloud_off,
                  color: sessionExpired ? AppColors.warning : AppColors.coral,
                  size: 38),
              const SizedBox(height: 14),
              Text(sessionExpired ? 'Sign in required' : 'Events unavailable',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: sessionExpired ? signIn : retry,
                  child: Text(sessionExpired ? 'Sign in again' : 'Try again'),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.repository,
    required this.user,
    required this.openAccount,
  });
  final EventsController controller;
  final EventWorkspaceRepository repository;
  final AuthUser user;
  final VoidCallback openAccount;

  static const filters = [
    ('all', 'All'),
    ('needs_attention', 'Needs Attention'),
    ('preparing', 'Preparing'),
    ('ready', 'Ready'),
    ('live', 'Live'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled')
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const ProwemBrand(compact: true, horizontal: true),
            const Spacer(),
            _CircleButton(
                icon: Icons.notifications_none,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) =>
                        NotificationsPage(repository: repository)))),
          ]),
          const SizedBox(height: 16),
          InkWell(
            onTap: openAccount,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x9912161E),
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                _UserAvatar(user: user),
                const SizedBox(width: 11),
                Expanded(child: _AccountIdentity(user: user)),
                const Icon(Icons.expand_more_rounded, color: AppColors.muted),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          const Text('My Events',
              style: TextStyle(
                  fontSize: 32, height: 1.05, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('Monitor event readiness and act on what needs attention.',
              style: TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 22),
          _EventFilterControl(
            filters: filters,
            selected: controller.filter,
            summary: controller.summary,
            onSelected: controller.setFilter,
          ),
        ]),
      );
}

class _EventFilterControl extends StatelessWidget {
  const _EventFilterControl({
    required this.filters,
    required this.selected,
    required this.summary,
    required this.onSelected,
  });

  final List<(String, String)> filters;
  final String selected;
  final EventSummary summary;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final current = filters.firstWhere((item) => item.$1 == selected);
    final count = summary[selected];
    final tone = _filterTone(selected);

    return Material(
      color: const Color(0xFF11151B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showFilters(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.tune_rounded, color: tone, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SHOWING',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${current.$2} · $count ${count == 1 ? 'event' : 'events'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Change',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.expand_more_rounded,
                  color: AppColors.coral, size: 21),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Filter events',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose which events you want to see.',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...filters.map((item) {
                final active = item.$1 == selected;
                final itemTone = _filterTone(item.$1);
                final itemCount = summary[item.$1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Material(
                    color: active
                        ? AppColors.coral.withValues(alpha: .11)
                        : const Color(0xFF11151B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: active
                            ? AppColors.coral.withValues(alpha: .55)
                            : AppColors.border,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(item.$1),
                      child: SizedBox(
                        height: 52,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(children: [
                            Icon(
                              active
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: active ? AppColors.coral : AppColors.muted,
                              size: 21,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.$2,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 28),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: itemTone.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '$itemCount',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: itemTone,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
    if (value != null && value != selected) onSelected(value);
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF151A1F),
              border: Border.all(color: AppColors.border)),
          child: Icon(icon)));
}

class _EventCardView extends StatelessWidget {
  const _EventCardView(
      {required this.event,
      required this.workspaceRepository,
      required this.onChanged});
  final EventCard event;
  final EventWorkspaceRepository workspaceRepository;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final issues = event.openIncidents + event.openTickets;
    final tone = _eventTone(event);
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => EventWorkspacePage(
                event: event, repository: workspaceRepository)));
        await onChanged();
      },
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(
                color: event.status == 'live' ? tone : AppColors.border),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 18,
                  offset: Offset(0, 8))
            ]),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Crest(name: event.name, tone: tone),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(event.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      _Status(status: event.status, tone: tone),
                      const SizedBox(height: 14),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppColors.muted),
                        const SizedBox(width: 7),
                        Expanded(
                            child: Text(event.venue ?? 'Venue pending',
                                style: const TextStyle(color: AppColors.muted)))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 17, color: AppColors.muted),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_dateRange(event),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.muted)))
                      ]),
                    ])),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ])),
          const Divider(height: 1, color: Color(0x227D8790)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _Footer(event: event, issues: issues)),
        ]),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.event, required this.issues});
  final EventCard event;
  final int issues;
  @override
  Widget build(BuildContext context) {
    if (event.status == 'completed') {
      return const _MessageIcon(
          icon: Icons.check,
          title: 'Event completed',
          subtitle: 'Thank you for a great event!');
    }
    if (event.status == 'cancelled') {
      return const _MessageIcon(
          icon: Icons.block,
          title: 'Event cancelled',
          subtitle: 'No further actions required.');
    }
    if (event.status == 'ready') {
      return Row(children: [
        _Progress(score: event.readinessScore, color: AppColors.lime),
        const SizedBox(width: 20),
        const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ready for kickoff',
              style: TextStyle(
                  color: AppColors.lime, fontWeight: FontWeight.w700)),
          SizedBox(height: 5),
          Text('All tasks complete', style: TextStyle(color: AppColors.muted))
        ]))
      ]);
    }
    if (event.status == 'preparing') {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _Progress(score: event.readinessScore, color: AppColors.warning),
        _Metric(
            value: event.criticalBlockers,
            label: 'BLOCKERS',
            color: AppColors.warning)
      ]);
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _Metric(
          value: event.criticalIncidents,
          label: 'CRITICAL',
          color: AppColors.danger),
      _Metric(value: issues, label: 'OPEN ISSUES', color: AppColors.danger)
    ]);
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.score, required this.color});
  final int score;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 68,
      height: 68,
      child: Stack(fit: StackFit.expand, children: [
        CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 6,
            backgroundColor: const Color(0xFF30363C),
            color: color),
        Center(
            child: Text('$score%',
                style: TextStyle(color: color, fontWeight: FontWeight.w700)))
      ]));
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.value, required this.label, required this.color});
  final int value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text('$value',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 5),
        CircleAvatar(radius: 4, backgroundColor: color)
      ]);
}

class _MessageIcon extends StatelessWidget {
  const _MessageIcon(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.muted, width: 2)),
            child: Icon(icon, color: AppColors.muted)),
        const SizedBox(width: 18),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: AppColors.muted))
        ]))
      ]);
}

class _Status extends StatelessWidget {
  const _Status({required this.status, required this.tone});
  final String status;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      'ready' => Icons.check_circle,
      'live' => Icons.sensors,
      'preparing' => Icons.warning_amber_rounded,
      'completed' => Icons.task_alt,
      _ => Icons.block,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          border: Border.all(color: tone),
          borderRadius: BorderRadius.circular(5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: tone, size: 14),
        const SizedBox(width: 5),
        Text(status.toUpperCase(),
            style: TextStyle(
                color: tone, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest({required this.name, required this.tone});
  final String name;
  final Color tone;
  @override
  Widget build(BuildContext context) => Container(
      width: 68,
      height: 82,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(color: tone, width: 2),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30), bottom: Radius.circular(38))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          name.split(' ').take(3).map((word) => word[0]).join(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Icon(Icons.sports_soccer, size: 16, color: tone)
      ]));
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});
  final AuthUser user;

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.coral.withValues(alpha: .1),
          border: Border.all(color: AppColors.coral.withValues(alpha: .65)),
        ),
        child: Text(
          _initials(user.name),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
}

class _AccountIdentity extends StatelessWidget {
  const _AccountIdentity({required this.user, this.centered = false});
  final AuthUser user;
  final bool centered;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (centered) ...[
            _UserAvatar(user: user),
            const SizedBox(height: 12),
          ],
          Text(user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          if (centered) ...[
            const SizedBox(height: 5),
            Text(user.role.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                    color: AppColors.coral,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
          ],
        ],
      );
}

class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = Colors.white,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        minTileHeight: 62,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      );
}

Color _eventTone(EventCard event) {
  if (event.status == 'live' && event.criticalIncidents > 0) {
    return AppColors.danger;
  }
  return _tone(event.status);
}

Color _filterTone(String filter) => switch (filter) {
      'needs_attention' => AppColors.danger,
      'preparing' => AppColors.warning,
      'ready' => AppColors.lime,
      'live' => AppColors.cyan,
      'all' => AppColors.coral,
      _ => AppColors.muted,
    };

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

Color _tone(String status) => switch (status) {
      'live' => AppColors.cyan,
      'preparing' => AppColors.warning,
      'ready' => AppColors.lime,
      _ => AppColors.muted
    };
String _dateRange(EventCard event) {
  String one(DateTime date) => '${_months[date.month - 1]} ${date.day}';
  return '${one(event.startsAt)} – ${one(event.endsAt)}, ${event.endsAt.year}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];
