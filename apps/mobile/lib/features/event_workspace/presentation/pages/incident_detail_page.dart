import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/event_workspace_repository.dart';
import 'ticket_detail_page.dart';
import '../widgets/event_navigation_bar.dart';

class IncidentDetailPage extends StatefulWidget {
  const IncidentDetailPage(
      {required this.eventId,
      required this.incidentId,
      required this.repository,
      super.key});
  final int eventId;
  final int incidentId;
  final EventWorkspaceRepository repository;
  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  late Future<Map<String, dynamic>> _loader =
      widget.repository.incident(widget.incidentId);
  bool _saving = false;
  String? _error;

  void _reload() =>
      setState(() => _loader = widget.repository.incident(widget.incidentId));

  Future<void> _update(String status, {String? resolution}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository
          .updateIncident(widget.incidentId, status, resolution: resolution);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'resolved'
              ? 'Incident resolved.'
              : 'Incident updated.')));
      _reload();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resolve() async {
    final controller = TextEditingController();
    final resolution = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 4, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Resolve incident',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text(
                  'Describe the corrective action. This resolution is saved in the Event Care history.',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 14),
              TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Resolution',
                      hintText: 'Backup referee confirmed.')),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(context, controller.text.trim());
                    }
                  },
                  child: const Text('Resolve issue')),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
            ]),
      ),
    );
    controller.dispose();
    if (resolution != null) await _update('resolved', resolution: resolution);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Incident detail'), actions: [
          IconButton(
              onPressed: _saving ? null : _reload,
              icon: const Icon(Icons.refresh))
        ]),
        body: FutureBuilder<Map<String, dynamic>>(
            future: _loader,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final incident = snapshot.data!;
              final technical = incident['type'] == 'technical';
              final status = incident['status'] as String;
              final ticket = incident['ticket'] is Map<String, dynamic>
                  ? incident['ticket'] as Map<String, dynamic>
                  : null;
              final fixture = incident['fixture'] is Map<String, dynamic>
                  ? incident['fixture'] as Map<String, dynamic>
                  : null;
              final venue = incident['venue'] is Map<String, dynamic>
                  ? incident['venue'] as Map<String, dynamic>
                  : null;
              return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _loader;
                  },
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Row(children: [
                      Expanded(
                          child: Text(incident['title'] as String,
                              style: const TextStyle(
                                  fontSize: 27, fontWeight: FontWeight.w900))),
                      _Chip(label: status, color: _status(status))
                    ]),
                    const SizedBox(height: 8),
                    Text(incident['description'] as String,
                        style: const TextStyle(
                            color: AppColors.muted, height: 1.5)),
                    const SizedBox(height: 18),
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color:
                                (technical ? AppColors.purple : AppColors.cyan)
                                    .withValues(alpha: .1),
                            border: Border.all(
                                color: technical
                                    ? AppColors.purple
                                    : AppColors.cyan),
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                  technical
                                      ? Icons.support_agent
                                      : Icons.person_pin_circle_outlined,
                                  color: technical
                                      ? AppColors.purple
                                      : AppColors.cyan),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        technical
                                            ? 'PROWEM is handling this'
                                            : 'Organizer action required',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Text(
                                        technical
                                            ? 'Technical ownership, diagnosis and SLA are managed by PROWEM Support.'
                                            : 'This is an operational issue owned by the tournament Organizer.',
                                        style: const TextStyle(
                                            color: AppColors.muted))
                                  ]))
                            ])),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.danger))
                    ],
                    const SizedBox(height: 18),
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              if (fixture != null)
                                _Fact(
                                    label: 'Affected match',
                                    value: 'Match #${fixture['number']}'),
                              if (venue != null)
                                _Fact(
                                    label: 'Venue',
                                    value: venue['name'] as String),
                              if (fixture != null)
                                _Fact(
                                    label: 'Kickoff',
                                    value: _kickoffContext(
                                        fixture['kickoff_at'] as String)),
                              _Fact(
                                  label: 'Type', value: '${incident['type']}'),
                              _Fact(
                                  label: 'Category',
                                  value: '${incident['category']}'),
                              _Fact(
                                  label: 'Severity',
                                  value: '${incident['severity']}'),
                              if (incident['resolution'] != null)
                                _Fact(
                                    label: 'Resolution',
                                    value: incident['resolution'] as String),
                            ]))),
                    if (technical && ticket != null) ...[
                      const SizedBox(height: 12),
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                        '${ticket['reference']} · ${ticket['priority']}'
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: AppColors.purple,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    Text(
                                        'SLA ${ticket['sla_status']} · ${ticket['assignee'] == null ? 'PROWEM Support assigned' : (ticket['assignee'] as Map<String, dynamic>)['name']}'),
                                    const SizedBox(height: 14),
                                    FilledButton.icon(
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    TicketDetailPage(
                                                        eventId: widget.eventId,
                                                        ticketId:
                                                            ticket['id'] as int,
                                                        repository: widget
                                                            .repository))),
                                        icon: const Icon(Icons.forum_outlined),
                                        label:
                                            const Text('View support ticket'))
                                  ]))),
                    ],
                    if (!technical && status != 'resolved') ...[
                      const SizedBox(height: 18),
                      if (status == 'open')
                        OutlinedButton(
                            onPressed:
                                _saving ? null : () => _update('acknowledged'),
                            child: const Text('Acknowledge incident')),
                      if (status == 'acknowledged')
                        OutlinedButton(
                            onPressed:
                                _saving ? null : () => _update('in_progress'),
                            child: const Text('Start handling')),
                      const SizedBox(height: 8),
                      FilledButton(
                          onPressed: _saving ? null : _resolve,
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Resolve issue')),
                    ],
                  ]));
            }),
        bottomNavigationBar: EventNavigationBar(
          eventId: widget.eventId,
          repository: widget.repository,
          selectedIndex: 1,
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(999)),
      child: Text(label.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)));
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(color: AppColors.muted))),
        Expanded(
            child: Text(value.replaceAll('_', ' '),
                style: const TextStyle(fontWeight: FontWeight.w600)))
      ]));
}

Color _status(String status) => switch (status) {
      'resolved' => AppColors.lime,
      'in_progress' => AppColors.cyan,
      'acknowledged' => AppColors.warning,
      _ => AppColors.danger
    };

String _kickoffContext(String value) {
  final kickoff = DateTime.parse(value).toLocal();
  final minutes = kickoff.difference(DateTime.now()).inMinutes;
  if (minutes > 0 && minutes < 120) return 'in $minutes min';
  if (minutes <= 0 && minutes > -120) return '${minutes.abs()} min ago';
  final minute = kickoff.minute.toString().padLeft(2, '0');
  return '${kickoff.hour.toString().padLeft(2, '0')}:$minute';
}
