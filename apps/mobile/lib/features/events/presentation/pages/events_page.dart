import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/event_card.dart';
import '../controllers/events_controller.dart';
import '../../../auth/presentation/widgets/prowem_brand.dart';
import '../../../event_workspace/data/event_workspace_repository.dart';
import '../../../event_workspace/presentation/pages/event_workspace_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage(
      {required this.controller, required this.workspaceRepository, super.key});
  final EventsController controller;
  final EventWorkspaceRepository workspaceRepository;

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
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _Header(
                        controller: widget.controller,
                        repository: widget.workspaceRepository)),
                if (widget.controller.isLoading)
                  const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()))
                else if (widget.controller.errorMessage case final error?)
                  SliverFillRemaining(child: Center(child: Text(error)))
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
      return <Widget>[
        Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 7),
            child: Text(
                status == 'preparing' ? 'UPCOMING' : status.toUpperCase(),
                style: TextStyle(
                    color: _tone(status),
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

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.repository});
  final EventsController controller;
  final EventWorkspaceRepository repository;

  static const filters = [
    ('all', 'All'),
    ('needs_attention', 'Needs Attention'),
    ('preparing', 'Preparing'),
    ('ready', 'Ready'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled')
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const ProwemBrand(compact: true, horizontal: true),
            const Spacer(),
            _CircleButton(
                icon: Icons.notifications_none,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) =>
                        NotificationsPage(repository: repository)))),
            const SizedBox(width: 16)
          ]),
          const SizedBox(height: 38),
          const Text('My Events',
              style: TextStyle(
                  fontSize: 38, height: 1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('Monitor event readiness and act on what needs attention.',
              style: TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 26),
          SizedBox(
              height: 50,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = filters[index];
                    final active = controller.filter == item.$1;
                    return OutlinedButton(
                        onPressed: () => controller.setFilter(item.$1),
                        style: OutlinedButton.styleFrom(
                            backgroundColor: active
                                ? const Color(0x26FF6B3D)
                                : Colors.transparent,
                            foregroundColor:
                                active ? AppColors.coral : AppColors.muted,
                            side: BorderSide(
                                color: active
                                    ? const Color(0x66FF6B3D)
                                    : AppColors.border),
                            shape: const StadiumBorder()),
                        child: Row(children: [
                          Text(item.$2),
                          const SizedBox(width: 9),
                          CircleAvatar(
                              radius: 11,
                              backgroundColor: active
                                  ? const Color(0x33FF6B3D)
                                  : const Color(0xFF20262C),
                              child: Text('${controller.summary[item.$1]}',
                                  style: const TextStyle(fontSize: 11)))
                        ]));
                  })),
        ]),
      );
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
                color: event.status == 'live'
                    ? AppColors.danger
                    : AppColors.border),
            borderRadius: BorderRadius.circular(16),
            boxShadow: event.status == 'live'
                ? const [BoxShadow(color: Color(0x33FF3B4E), blurRadius: 22)]
                : const [
                    BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 24,
                        offset: Offset(0, 10))
                  ]),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(18),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Crest(name: event.name, status: event.status),
                const SizedBox(width: 18),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(event.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _Status(status: event.status),
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
                        Text(_dateRange(event),
                            style: const TextStyle(color: AppColors.muted))
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
  const _Status({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          border: Border.all(color: _tone(status)),
          borderRadius: BorderRadius.circular(5)),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: _tone(status), fontSize: 11)));
}

class _Crest extends StatelessWidget {
  const _Crest({required this.name, required this.status});
  final String name;
  final String status;
  @override
  Widget build(BuildContext context) => Container(
      width: 88,
      height: 104,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(color: _tone(status), width: 2),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30), bottom: Radius.circular(38))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ...name.toUpperCase().split(' ').take(3).map((word) => Text(word,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, height: 1.05, fontWeight: FontWeight.w800))),
        const SizedBox(height: 5),
        const Text('⚽')
      ]));
}

Color _tone(String status) => switch (status) {
      'live' => AppColors.danger,
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
