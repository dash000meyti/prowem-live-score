import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../events/domain/entities/event_card.dart';
import '../../data/event_workspace_repository.dart';
import '../resource_mode.dart';
import 'team_passport_page.dart';
import 'resource_list_page.dart';
import 'support_home_page.dart';
import 'incident_detail_page.dart';
import 'ticket_detail_page.dart';

class EventWorkspacePage extends StatefulWidget {
  const EventWorkspacePage(
      {required this.event, required this.repository, super.key});
  final EventCard event;
  final EventWorkspaceRepository repository;

  @override
  State<EventWorkspacePage> createState() => _EventWorkspacePageState();
}

class _EventWorkspacePageState extends State<EventWorkspacePage> {
  late Future<Map<String, dynamic>> overview = loadOverview();
  bool transitioning = false;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && !transitioning) reload();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> loadOverview() async {
    final data = await widget.repository.overview(widget.event.id);
    final event = data['event'] as Map<String, dynamic>;
    if (event['status'] == 'live') {
      data['_live'] = await widget.repository.live(widget.event.id);
    }
    return data;
  }

  void reload() => setState(() => overview = loadOverview());

  void open(String title, Future<Object> loader, ResourceMode mode) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ResourceListPage(
            title: title,
            loader: loader,
            mode: mode,
            eventId: widget.event.id,
            repository: widget.repository)));
  }

  Future<void> startEvent() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Start event?'),
                content: const Text(
                    'Readiness is complete. Starting moves the Event into Live mode and notifies Event Care clients.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Start event'))
                ]));
    if (confirmed != true) return;
    setState(() => transitioning = true);
    try {
      await widget.repository.transitionEvent(widget.event.id, 'live');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Event is now live.')));
      reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$error'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => transitioning = false);
    }
  }

  Future<void> confirmReady() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Confirm Event ready?'),
                content: const Text(
                    'All readiness checks are complete. Confirm that the Event is ready for kickoff.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirm ready'))
                ]));
    if (confirmed != true) return;
    setState(() => transitioning = true);
    try {
      await widget.repository.transitionEvent(widget.event.id, 'ready');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event is ready for kickoff.')));
      reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$error'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => transitioning = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const _HeaderBrand(),
          actions: [
            IconButton(onPressed: reload, icon: const Icon(Icons.refresh)),
            const SizedBox(width: 6)
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: overview,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _LoadError(message: '${snapshot.error}', retry: reload);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                reload();
                await overview;
              },
              child: _EventHomeBody(
                  event: widget.event,
                  data: data,
                  repository: widget.repository,
                  open: open,
                  refresh: reload,
                  confirmReady: confirmReady,
                  startEvent: startEvent,
                  transitioning: transitioning),
            );
          },
        ),
        bottomNavigationBar: _EventBottomNav(
          onSelect: (index) {
            if (index == 0) return;
            if (index == 1) {
              open(
                  'Event checklists',
                  widget.repository.readiness(widget.event.id),
                  ResourceMode.readiness);
            }
            if (index == 2) {
              open('Matches', widget.repository.live(widget.event.id),
                  ResourceMode.live);
            }
            if (index == 3) {
              open('Teams', widget.repository.teams(widget.event.id),
                  ResourceMode.teams);
            }
            if (index == 4) {
              Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => SupportHomePage(
                      eventId: widget.event.id,
                      repository: widget.repository)));
            }
          },
        ),
      );
}

class _EventHomeBody extends StatelessWidget {
  const _EventHomeBody(
      {required this.event,
      required this.data,
      required this.repository,
      required this.open,
      required this.refresh,
      required this.confirmReady,
      required this.startEvent,
      required this.transitioning});
  final EventCard event;
  final Map<String, dynamic> data;
  final EventWorkspaceRepository repository;
  final void Function(String, Future<Object>, ResourceMode) open;
  final VoidCallback refresh;
  final VoidCallback confirmReady;
  final VoidCallback startEvent;
  final bool transitioning;

  @override
  Widget build(BuildContext context) {
    final readiness = data['readiness'] as Map<String, dynamic>;
    final attention = data['needs_attention'] as List<dynamic>;
    final matches = data['next_matches'] as List<dynamic>;
    final activity = data['recent_activity'] as List<dynamic>;
    final eventData = data['event'] as Map<String, dynamic>;
    final status = eventData['status'] as String;
    final criticalIncidents = data['open_critical_incidents'] as List<dynamic>;
    final openTickets = data['open_tickets'] as List<dynamic>;
    final live = data['_live'] as Map<String, dynamic>?;
    final operationalIncidents =
        live?['operational_incidents'] as List<dynamic>? ?? const [];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _EventIdentity(event: event),
        const SizedBox(height: 18),
        if (status == 'live')
          _LivePriority(
              incidents: criticalIncidents,
              operationalIncidents: operationalIncidents,
              tickets: openTickets,
              repository: repository,
              onChanged: refresh)
        else
          _ReadinessHero(readiness: readiness),
        if (status == 'ready') ...[
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: transitioning ? null : startEvent,
              icon: const Icon(Icons.play_arrow),
              label: Text(transitioning ? 'Starting…' : 'Start event')),
          const SizedBox(height: 4),
          OutlinedButton(
              onPressed: () => open('Event checklists',
                  repository.readiness(event.id), ResourceMode.readiness),
              child: const Text('Review readiness'))
        ],
        if (status == 'preparing' && readiness['status'] == 'ready') ...[
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: transitioning ? null : confirmReady,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(transitioning ? 'Confirming…' : 'Confirm ready')),
          const SizedBox(height: 6),
          const Text(
              'All checks are complete. Confirm readiness to unlock Start Event.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 14)),
        ],
        if (status == 'completed') ...[
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: () => open('Event Care report',
                  repository.report(event.id), ResourceMode.report),
              icon: const Icon(Icons.insights_outlined),
              label: const Text('View Event Care report'))
        ],
        const SizedBox(height: 24),
        _SectionHeader(
            title: status == 'live' ? 'Operational context' : 'Needs attention',
            label: 'View all (${attention.length})',
            onTap: () => open('Event checklists',
                repository.readiness(event.id), ResourceMode.readiness)),
        const SizedBox(height: 10),
        if (attention.isEmpty)
          const _EmptyCard(label: 'Everything is on track.')
        else
          ...attention.take(3).toList().asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _AttentionCard(
                  item: entry.value as Map<String, dynamic>,
                  index: entry.key + 1,
                  onTap: () {
                    final item = entry.value as Map<String, dynamic>;
                    if (item['subject_type'] == 'team' &&
                        item['subject_id'] != null) {
                      Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => TeamPassportPage(
                                      eventId: event.id,
                                      teamId: item['subject_id'] as int,
                                      repository: repository)))
                          .then((_) => refresh());
                    } else {
                      open(
                          _title(item['dimension']),
                          repository.dimension(
                              event.id, item['dimension'] as String),
                          ResourceMode.readiness);
                    }
                  }))),
        const SizedBox(height: 16),
        _SectionHeader(
            title: 'Upcoming matches',
            label: 'Full schedule',
            onTap: () =>
                open('Matches', repository.live(event.id), ResourceMode.live)),
        const SizedBox(height: 10),
        _GlassList(
            children: matches.isEmpty
                ? [const _EmptyRow(label: 'No upcoming matches.')]
                : matches
                    .take(4)
                    .map((raw) => _MatchRow(match: raw as Map<String, dynamic>))
                    .toList()),
        const SizedBox(height: 24),
        _SectionHeader(
            title: 'Recent activity',
            label: 'View all',
            onTap: () => open('Activity', repository.activity(event.id),
                ResourceMode.activity)),
        const SizedBox(height: 10),
        _GlassList(
            children: activity.isEmpty
                ? [const _EmptyRow(label: 'No recent activity.')]
                : activity
                    .take(5)
                    .map((raw) =>
                        _ActivityRow(item: raw as Map<String, dynamic>))
                    .toList()),
      ],
    );
  }
}

class _HeaderBrand extends StatelessWidget {
  const _HeaderBrand();
  @override
  Widget build(BuildContext context) =>
      const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shield_outlined, color: AppColors.coral),
        SizedBox(width: 9),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PROWEM',
              style: TextStyle(
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          Text('EVENT CARE',
              style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1))
        ])
      ]);
}

class _EventIdentity extends StatelessWidget {
  const _EventIdentity({required this.event});
  final EventCard event;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Crest(name: event.name),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event.name,
              style: const TextStyle(
                  fontSize: 23, height: 1.08, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined,
                size: 18, color: AppColors.muted),
            const SizedBox(width: 5),
            Expanded(
                child: Text(event.venue ?? 'Venue pending',
                    style: const TextStyle(color: AppColors.muted)))
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 17, color: AppColors.muted),
            const SizedBox(width: 6),
            Text(_dateRange(event.startsAt, event.endsAt),
                style: const TextStyle(color: AppColors.muted))
          ])
        ]))
      ]);
}

class _Crest extends StatelessWidget {
  const _Crest({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').take(3).map((part) => part[0]).join();
    return Container(
        width: 70,
        height: 82,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 2),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30), bottom: Radius.circular(40)),
            gradient: const RadialGradient(
                colors: [Color(0x44FF6B3D), Color(0xFF0A1016)])),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(initials,
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('EVENT CARE',
              style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 12,
                  fontWeight: FontWeight.w700))
        ]));
  }
}

class _ReadinessHero extends StatelessWidget {
  const _ReadinessHero({required this.readiness});
  final Map<String, dynamic> readiness;
  @override
  Widget build(BuildContext context) {
    final status = readiness['status'] as String;
    final tone = status == 'blocked'
        ? AppColors.danger
        : status == 'warning'
            ? AppColors.warning
            : AppColors.lime;
    final blocked = status == 'blocked';
    final title = blocked
        ? 'EVENT NOT READY'
        : status == 'warning'
            ? 'ATTENTION REQUIRED'
            : 'READY FOR KICKOFF';
    final icon = blocked
        ? Icons.cancel
        : status == 'warning'
            ? Icons.warning_amber_rounded
            : Icons.check_circle;
    return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            border: Border.all(color: tone.withValues(alpha: .55)),
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
                colors: [tone.withValues(alpha: .12), AppColors.surface]),
            boxShadow: [
              BoxShadow(color: tone.withValues(alpha: .1), blurRadius: 28)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, color: tone, size: 24),
            const SizedBox(width: 9),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: tone,
                        fontSize: 16,
                        fontWeight: FontWeight.w900))),
            Text('${readiness['score']}%',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (readiness['score'] as num) / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFF34373C),
              color: tone,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 18, runSpacing: 8, children: [
            _ReadinessFact(
              icon: Icons.error_outline,
              value: '${readiness['critical_blockers_count']}',
              label: 'critical blockers',
              color: blocked ? AppColors.danger : AppColors.muted,
            ),
            _ReadinessFact(
              icon: Icons.task_alt,
              value: '${readiness['actions_required_count']}',
              label: 'actions required',
              color: status == 'ready' ? AppColors.lime : AppColors.warning,
            ),
          ]),
        ]));
  }
}

class _ReadinessFact extends StatelessWidget {
  const _ReadinessFact({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text('$value $label',
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ]);
}

class _LivePriority extends StatelessWidget {
  const _LivePriority(
      {required this.incidents,
      required this.operationalIncidents,
      required this.tickets,
      required this.repository,
      required this.onChanged});
  final List<dynamic> incidents;
  final List<dynamic> operationalIncidents;
  final List<dynamic> tickets;
  final EventWorkspaceRepository repository;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final incidentById = <int, Map<String, dynamic>>{};
    for (final raw in [...incidents, ...operationalIncidents]) {
      final incident = raw as Map<String, dynamic>;
      incidentById[incident['id'] as int] = incident;
    }
    final representedTickets = <int>{};
    for (final incident in incidentById.values) {
      final ticket = incident['ticket'];
      if (ticket is Map<String, dynamic> && ticket['id'] is int) {
        representedTickets.add(ticket['id'] as int);
      }
    }
    final visibleTickets = tickets
        .where((raw) =>
            !representedTickets.contains((raw as Map<String, dynamic>)['id']))
        .toList();
    final count = incidentById.length + visibleTickets.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.surface,
          border:
              Border.all(color: count > 0 ? AppColors.danger : AppColors.lime),
          borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(count > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
              color: count > 0 ? AppColors.danger : AppColors.lime),
          const SizedBox(width: 9),
          Expanded(
              child: Text(
                  count > 0 ? 'NEEDS ACTION NOW' : 'EVENT PULSE HEALTHY',
                  style: TextStyle(
                      color: count > 0 ? AppColors.danger : AppColors.lime,
                      fontWeight: FontWeight.w900))),
          Text('$count open', style: const TextStyle(color: AppColors.muted))
        ]),
        if (incidentById.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...(incidentById.values.take(3).map((item) {
            final technical = item['type'] == 'technical';
            final linked = item['ticket'] is Map<String, dynamic>
                ? item['ticket'] as Map<String, dynamic>
                : null;
            return ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.warning_amber, color: AppColors.danger),
                title: Text(item['title'] as String),
                subtitle: Text(
                    technical
                        ? 'PROWEM Support is handling this'
                        : 'Your team needs to handle this',
                    style: TextStyle(
                        color: technical ? AppColors.purple : AppColors.muted)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => linked == null
                              ? IncidentDetailPage(
                                  incidentId: item['id'] as int,
                                  repository: repository)
                              : TicketDetailPage(
                                  ticketId: linked['id'] as int,
                                  repository: repository)));
                  onChanged();
                });
          })),
        ],
        if (visibleTickets.isNotEmpty) ...[
          const Divider(),
          ...(visibleTickets.take(2).map((raw) {
            final item = raw as Map<String, dynamic>;
            return ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.support_agent, color: AppColors.purple),
                title: Text(item['subject'] as String),
                subtitle: Text(
                    'PROWEM Support · ${item['priority']}'.toUpperCase(),
                    style: const TextStyle(color: AppColors.purple)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => TicketDetailPage(
                              ticketId: item['id'] as int,
                              repository: repository)));
                  onChanged();
                });
          })),
        ],
        if (count == 0)
          const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                  'No operational or technical issue requires attention.',
                  style: TextStyle(color: AppColors.muted))),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.label, required this.onTap});
  final String title;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800))),
        TextButton(
            onPressed: onTap,
            child: Row(children: [
              Text(label),
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right, size: 18)
            ]))
      ]);
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard(
      {required this.item, required this.index, required this.onTap});
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final critical = item['status'] == 'blocked' || item['is_critical'] == true;
    final tone = critical ? AppColors.danger : AppColors.warning;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
        decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16)),
        child: IntrinsicHeight(
            child: Row(children: [
          Container(
              width: 5,
              decoration: BoxDecoration(
                  color: tone,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16)))),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Stack(clipBehavior: Clip.none, children: [
                      CircleAvatar(
                          radius: 28,
                          backgroundColor: tone.withValues(alpha: .14),
                          child: Icon(
                              _attentionIcon(item['dimension'] as String),
                              color: tone)),
                      Positioned(
                          top: -6,
                          left: -5,
                          child: CircleAvatar(
                              radius: 10,
                              backgroundColor: tone,
                              child: Text('$index',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800))))
                    ]),
                    const SizedBox(width: 13),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(critical ? 'CRITICAL' : 'WARNING',
                              style: TextStyle(
                                  color: tone,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(
                              item['message'] as String? ??
                                  _title(item['check_type']),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              '${_title(item['dimension'])} requires attention.',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12))
                        ])),
                    const SizedBox(width: 8),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(critical ? 'Resolve' : 'Review',
                          style: TextStyle(
                              color: tone,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      Icon(Icons.chevron_right, color: tone, size: 20),
                    ])
                  ])))
        ]))),
      ),
    );
  }
}

class _GlassList extends StatelessWidget {
  const _GlassList({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
          children: children.expand((child) sync* {
        if (child != children.first) yield const Divider(height: 1);
        yield child;
      }).toList()));
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});
  final Map<String, dynamic> match;
  @override
  Widget build(BuildContext context) {
    final home = match['home_team'] as Map<String, dynamic>?;
    final away = match['away_team'] as Map<String, dynamic>?;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          SizedBox(
              width: 58,
              child: Text(_time(match['kickoff_at'] as String),
                  style: const TextStyle(
                      color: AppColors.cyan, fontWeight: FontWeight.w700))),
          Expanded(
              child: Text(
                  '${home?['name'] ?? 'TBC'}  vs  ${away?['name'] ?? 'TBC'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(match['field'] as String? ?? 'TBC',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const Icon(Icons.chevron_right, color: AppColors.muted)
        ]));
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) {
    final danger = '${item['type']}'.contains('incident') ||
        '${item['type']}'.contains('issue');
    final tone = danger ? AppColors.danger : AppColors.lime;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          CircleAvatar(
              radius: 20,
              backgroundColor: tone.withValues(alpha: .14),
              child: Icon(danger ? Icons.warning_amber : Icons.check,
                  color: tone, size: 19)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item['title'] as String? ?? 'Event update',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(item['description'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12))
              ])),
          const SizedBox(width: 8),
          Text(_time(item['occurred_at'] as String),
              style: const TextStyle(color: AppColors.muted, fontSize: 12))
        ]));
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      height: 90,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: const TextStyle(color: AppColors.muted)));
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Text(label, style: const TextStyle(color: AppColors.muted)));
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: retry, child: const Text('Try again'))
          ])));
}

class _EventBottomNav extends StatelessWidget {
  const _EventBottomNav({required this.onSelect});
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Container(
          decoration: const BoxDecoration(
              color: Color(0xF205070A),
              border: Border(top: BorderSide(color: AppColors.border))),
          child: NavigationBar(
              height: 68,
              selectedIndex: 0,
              onDestinationSelected: onSelect,
              backgroundColor: Colors.transparent,
              indicatorColor: const Color(0x26FF6B3D),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home, color: AppColors.coral),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.checklist), label: 'Tasks'),
                NavigationDestination(
                    icon: Icon(Icons.sports_soccer), label: 'Matches'),
                NavigationDestination(
                    icon: Icon(Icons.groups_outlined), label: 'People'),
                NavigationDestination(
                    icon: Icon(Icons.headset_mic_outlined), label: 'Support')
              ])));
}

IconData _attentionIcon(String dimension) => switch (dimension) {
      'streaming' => Icons.sensors,
      'teams' => Icons.credit_card,
      'referees' => Icons.person_outline,
      _ => Icons.warning_amber
    };
String _title(Object? value) => '${value ?? 'Action required'}'
    .replaceAll('_', ' ')
    .split(' ')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');
String _time(String value) {
  final date = DateTime.parse(value).toLocal();
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
}

String _dateRange(DateTime from, DateTime to) =>
    '${_months[from.month - 1]} ${from.day} – ${_months[to.month - 1]} ${to.day}, ${to.year}';
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
