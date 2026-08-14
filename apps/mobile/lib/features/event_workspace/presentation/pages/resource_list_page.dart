import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/event_workspace_repository.dart';
import 'create_resource_page.dart';
import 'ticket_detail_page.dart';
import 'team_passport_page.dart';
import 'incident_detail_page.dart';
import '../resource_mode.dart';

class ResourceListPage extends StatefulWidget {
  const ResourceListPage(
      {required this.title,
      required this.loader,
      required this.mode,
      required this.eventId,
      required this.repository,
      super.key});
  final String title;
  final Future<Object> loader;
  final ResourceMode mode;
  final int eventId;
  final EventWorkspaceRepository repository;

  @override
  State<ResourceListPage> createState() => _ResourceListPageState();
}

class _ResourceListPageState extends State<ResourceListPage> {
  late Future<Object> loader = widget.loader;

  void reload() => setState(() {
        loader = switch (widget.mode) {
          ResourceMode.readiness => widget.repository.readiness(widget.eventId),
          ResourceMode.teams => widget.repository.teams(widget.eventId),
          ResourceMode.live => widget.repository.live(widget.eventId),
          ResourceMode.incidents => widget.repository.incidents(widget.eventId),
          ResourceMode.tickets => widget.repository.tickets(widget.eventId),
          ResourceMode.activity => widget.repository.activity(widget.eventId),
          ResourceMode.report => widget.repository.report(widget.eventId),
        };
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: [
          IconButton(onPressed: reload, icon: const Icon(Icons.refresh))
        ]),
        floatingActionButton: widget.mode == ResourceMode.incidents ||
                widget.mode == ResourceMode.tickets
            ? FloatingActionButton(
                onPressed: () async {
                  final created = await Navigator.of(context).push(
                      MaterialPageRoute<bool>(
                          builder: (_) => CreateResourcePage(
                              mode: widget.mode,
                              eventId: widget.eventId,
                              repository: widget.repository)));
                  if (created == true) reload();
                },
                child: const Icon(Icons.add),
              )
            : null,
        body: FutureBuilder<Object>(
            future: loader,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return switch (widget.mode) {
                ResourceMode.readiness => _Readiness(
                    data: snapshot.data! as Map<String, dynamic>,
                    eventId: widget.eventId,
                    repository: widget.repository),
                ResourceMode.live => _Live(
                    data: snapshot.data! as Map<String, dynamic>,
                    eventId: widget.eventId,
                    repository: widget.repository),
                ResourceMode.report =>
                  _Report(data: snapshot.data! as Map<String, dynamic>),
                _ => _List(
                    data: snapshot.data! as List<dynamic>,
                    mode: widget.mode,
                    eventId: widget.eventId,
                    repository: widget.repository,
                    onChanged: reload),
              };
            }),
      );
}

class _Readiness extends StatelessWidget {
  const _Readiness(
      {required this.data, required this.eventId, required this.repository});
  final Map<String, dynamic> data;
  final int eventId;
  final EventWorkspaceRepository repository;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(16), children: [
        _Score(
            score: data['score'] as int,
            label:
                '${data['status']} · ${data['critical_blockers_count']} critical blockers'),
        const SizedBox(height: 18),
        ...(data['dimensions'] as List).map((raw) {
          final item = raw as Map<String, dynamic>;
          return Card(
              child: ListTile(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => _DimensionPage(
                              title: item['label'] as String,
                              eventId: eventId,
                              repository: repository,
                              loader: repository.dimension(
                                  eventId, item['key'] as String)))),
                  title: Text(item['label'] as String),
                  subtitle: Text(
                      '${item['ready']}/${item['total']} ready · ${item['actions_required']} actions'),
                  trailing: Text('${item['score']}%',
                      style: TextStyle(
                          color: _statusColor(item['status'] as String),
                          fontWeight: FontWeight.w700))));
        }),
      ]);
}

class _DimensionPage extends StatelessWidget {
  const _DimensionPage(
      {required this.title,
      required this.loader,
      required this.eventId,
      required this.repository});
  final String title;
  final Future<Map<String, dynamic>> loader;
  final int eventId;
  final EventWorkspaceRepository repository;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<Map<String, dynamic>>(
          future: loader,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data!['items'] as List;
            return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index] as Map<String, dynamic>;
                  final subject = item['subject'] as Map<String, dynamic>?;
                  final teamId = subject != null && subject['type'] == 'team'
                      ? subject['id'] as int?
                      : null;
                  return Card(
                      child: ListTile(
                          onTap: teamId == null
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => TeamPassportPage(
                                          eventId: eventId,
                                          teamId: teamId,
                                          repository: repository))),
                          leading: Icon(Icons.circle,
                              size: 12,
                              color: _statusColor(item['status'] as String)),
                          title: Text(item['label'] as String),
                          subtitle: Text(item['message'] as String? ??
                              'No action required'),
                          trailing: teamId == null
                              ? Text(item['status'] as String)
                              : const Icon(Icons.chevron_right)));
                });
          }));
}

class _List extends StatelessWidget {
  const _List(
      {required this.data,
      required this.mode,
      required this.eventId,
      required this.repository,
      required this.onChanged});
  final List<dynamic> data;
  final ResourceMode mode;
  final int eventId;
  final EventWorkspaceRepository repository;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
          child: Text('Nothing to show.',
              style: TextStyle(color: AppColors.muted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = data[index] as Map<String, dynamic>;
        final info = _info(item);
        return Card(
            child: ListTile(
          leading: Icon(info.$3, color: info.$4),
          title: Text(info.$1),
          subtitle: Text(info.$2),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            if (mode == ResourceMode.tickets) {
              await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => TicketDetailPage(
                          ticketId: item['id'] as int,
                          repository: repository)));
            } else if (mode == ResourceMode.teams) {
              await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => TeamPassportPage(
                          eventId: eventId,
                          teamId: (item['team'] as Map<String, dynamic>)['id']
                              as int,
                          repository: repository)));
            } else if (mode == ResourceMode.incidents) {
              await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => IncidentDetailPage(
                          incidentId: item['id'] as int,
                          repository: repository)));
            }
            onChanged();
          },
        ));
      },
    );
  }

  (String, String, IconData, Color) _info(Map<String, dynamic> item) =>
      switch (mode) {
        ResourceMode.teams => (
            (item['team'] as Map<String, dynamic>)['name'] as String,
            '${item['score']}% · ${item['blockers_count']} blockers',
            Icons.groups_outlined,
            _statusColor(item['status'] as String)
          ),
        ResourceMode.incidents => (
            item['title'] as String,
            '${item['severity']} · ${item['status']}',
            Icons.warning_amber,
            _severityColor(item['severity'] as String)
          ),
        ResourceMode.tickets => (
            '${item['reference']} · ${item['subject']}',
            '${item['priority']} · ${item['status']} · SLA ${item['sla_status']}',
            Icons.support_agent,
            _statusColor(item['sla_status'] as String)
          ),
        ResourceMode.activity => (
            item['title'] as String,
            item['description'] as String,
            Icons.history,
            AppColors.muted
          ),
        _ => ('Item', '', Icons.circle, AppColors.muted),
      };
}

class _Live extends StatefulWidget {
  const _Live(
      {required this.data, required this.eventId, required this.repository});
  final Map<String, dynamic> data;
  final int eventId;
  final EventWorkspaceRepository repository;
  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  bool saving = false;
  String? error;

  Future<void> start() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Start event?'),
              content: const Text(
                  'Confirm that operations are ready. The event will move to Live mode.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Start event'))
              ],
            ));
    if (confirmed != true) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.repository.transitionEvent(widget.eventId, 'live');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Event is now live.')));
      Navigator.pop(context, true);
    } catch (value) {
      if (mounted) setState(() => error = '$value');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final progress = data['progress'] as Map<String, dynamic>;
    final status = (data['event'] as Map<String, dynamic>)['status'] as String;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _Score(
          score: progress['total'] == 0
              ? 0
              : ((progress['completed'] as int) *
                      100 /
                      (progress['total'] as int))
                  .round(),
          label:
              '${progress['completed']} of ${progress['total']} matches complete'),
      if (error != null)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child:
                Text(error!, style: const TextStyle(color: AppColors.danger))),
      if (status == 'ready')
        Padding(
            padding: const EdgeInsets.only(top: 14),
            child: FilledButton.icon(
                onPressed: saving ? null : start,
                icon: const Icon(Icons.play_arrow),
                label: Text(saving ? 'Starting…' : 'Start event'))),
      const SizedBox(height: 14),
      ...[
        'live_matches',
        'delayed_matches',
        'next_matches',
        'operational_incidents'
      ].map((key) {
        final items = data[key] as List;
        return Card(
            child: ExpansionTile(
          initiallyExpanded: key == 'operational_incidents' && items.isNotEmpty,
          title: Text(key.replaceAll('_', ' ').toUpperCase()),
          trailing: Text('${items.length}'),
          children: items.isEmpty
              ? [
                  const ListTile(
                      title: Text('Nothing to show.',
                          style: TextStyle(color: AppColors.muted)))
                ]
              : items.take(8).map((raw) {
                  final item = raw as Map<String, dynamic>;
                  return ListTile(
                    title: Text(
                        item['title'] as String? ?? 'Match #${item['number']}'),
                    subtitle: Text(
                        '${item['status']}${item['delay_minutes'] is num && (item['delay_minutes'] as num) > 0 ? ' · +${item['delay_minutes']} min' : ''}'),
                    onTap: key == 'operational_incidents'
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => IncidentDetailPage(
                                    incidentId: item['id'] as int,
                                    repository: widget.repository)))
                        : null,
                  );
                }).toList(),
        ));
      }),
      const Card(
          child: ListTile(
              leading: Icon(Icons.open_in_new, color: AppColors.cyan),
              title: Text('PROWEM Core Match Control'),
              subtitle: Text(
                  'Scoring remains in PROWEM Core; Event Care shows operational status only.'))),
    ]);
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final support = data['support'] as Map<String, dynamic>;
    final incidents = data['incidents'] as Map<String, dynamic>;
    final readiness = data['readiness'] as Map<String, dynamic>;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('EVENT OUTCOME',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.lime)),
      const SizedBox(height: 10),
      _Score(
          score: (readiness['score_before_kickoff'] as int?) ?? 0,
          label: 'Readiness before kickoff'),
      const SizedBox(height: 18),
      const Text('OPERATIONS',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      _MetricCard(title: 'Matches completed', value: '${data['match_count']}'),
      _MetricCard(
          title: 'Operational incidents', value: '${incidents['operational']}'),
      _MetricCard(
          title: 'Technical incidents', value: '${incidents['technical']}'),
      _MetricCard(
          title: 'Average delay',
          value: '${data['average_delay_minutes']} min'),
      const SizedBox(height: 18),
      const Text('PROWEM SUPPORT',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      _MetricCard(title: 'Support tickets', value: '${support['tickets']}'),
      _MetricCard(title: 'P1 tickets', value: '${support['p1']}'),
      _MetricCard(
          title: 'SLA compliance',
          value: support['sla_compliance_percent'] == null
              ? 'Not measured'
              : '${support['sla_compliance_percent']}%'),
      const SizedBox(height: 20),
      const Text('WHAT TO IMPROVE NEXT TIME',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ...(data['recommendations'] as List).map((item) => Card(
          child: ListTile(
              minVerticalPadding: 14,
              leading:
                  const Icon(Icons.lightbulb_outline, color: AppColors.coral),
              title: Text(item as String,
                  style: const TextStyle(fontSize: 15, height: 1.4)))))
    ]);
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.score, required this.label});
  final int score;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 10))
          ]),
      child: Row(children: [
        Text('$score%',
            style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: AppColors.lime)),
        const SizedBox(width: 18),
        Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)))
      ]));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          title: Text(title),
          trailing: Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))));
}

Color _statusColor(String status) => switch (status) {
      'ready' || 'met' || 'on_track' => AppColors.lime,
      'warning' || 'approaching' => Colors.orange,
      'blocked' || 'breached' => Colors.redAccent,
      _ => AppColors.muted
    };
Color _severityColor(String severity) => switch (severity) {
      'critical' => Colors.red,
      'high' => Colors.deepOrange,
      'medium' => Colors.orange,
      _ => AppColors.muted
    };
