import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/event_workspace_repository.dart';
import '../widgets/event_navigation_bar.dart';

class TicketDetailPage extends StatefulWidget {
  const TicketDetailPage(
      {required this.eventId,
      required this.ticketId,
      required this.repository,
      super.key});
  final int eventId;
  final int ticketId;
  final EventWorkspaceRepository repository;
  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final input = TextEditingController();
  late Future<
      (
        Map<String, dynamic>,
        List<dynamic>,
        Map<String, dynamic>,
        Map<String, dynamic>
      )> loader = _load();
  bool sending = false;
  bool updating = false;
  String? sendError;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !sending) reload();
    });
  }

  Future<(Map<String, dynamic>, List<dynamic>, Map<String, dynamic>, Map<String, dynamic>)>
      _load() async => (
            await widget.repository.ticket(widget.ticketId),
            await widget.repository.ticketMessages(widget.ticketId),
            await widget.repository.me(),
            await widget.repository.lookups(widget.eventId),
          );
  void reload() => setState(() => loader = _load());

  Future<void> send() async {
    final body = input.text.trim();
    if (body.isEmpty || sending) return;
    setState(() {
      sending = true;
      sendError = null;
    });
    try {
      await widget.repository.sendTicketMessage(widget.ticketId, body);
      input.clear();
      reload();
    } catch (error) {
      if (mounted) setState(() => sendError = '$error');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<bool> updateTicket(Map<String, dynamic> body) async {
    if (updating) return false;
    setState(() {
      updating = true;
      sendError = null;
    });
    try {
      await widget.repository.updateTicket(widget.ticketId, body);
      if (!mounted) return false;
      reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket updated.')),
      );
      return true;
    } catch (error) {
      if (mounted) setState(() => sendError = '$error');
      return false;
    } finally {
      if (mounted) setState(() => updating = false);
    }
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Support conversation'), actions: [
          IconButton(onPressed: reload, icon: const Icon(Icons.refresh))
        ]),
        body: FutureBuilder<
                (
                  Map<String, dynamic>,
                  List<dynamic>,
                  Map<String, dynamic>,
                  Map<String, dynamic>
                )>(
            future: loader,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: reload, child: const Text('Try again'))
                ]));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final ticket = snapshot.data!.$1;
              final messages = snapshot.data!.$2;
              final user = snapshot.data!.$3;
              final lookups = snapshot.data!.$4;
              final resolved = ticket['status'] == 'resolved';
              final supportUser = const {
                'support_agent',
                'support_lead',
                'admin'
              }.contains(user['role']);
              return Column(children: [
                Expanded(
                    child: RefreshIndicator(
                        onRefresh: () async {
                          reload();
                          await loader;
                        },
                        child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      border: Border.all(
                                          color: resolved
                                              ? AppColors.lime
                                              : ticket['priority'] == 'p1'
                                                  ? AppColors.danger
                                                  : AppColors.border),
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(ticket['reference'] as String,
                                            style: const TextStyle(
                                                color: AppColors.coral,
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 9),
                                        Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              _Pill(
                                                  '${ticket['priority']}'
                                                      .toUpperCase(),
                                                  ticket['priority'] == 'p1'
                                                      ? AppColors.danger
                                                      : AppColors.warning),
                                              _Pill(
                                                  '${ticket['status']}'
                                                      .replaceAll('_', ' ')
                                                      .toUpperCase(),
                                                  resolved
                                                      ? AppColors.lime
                                                      : AppColors.purple)
                                            ]),
                                        const SizedBox(height: 10),
                                        Text(ticket['subject'] as String,
                                            style: const TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 5),
                                        Text(ticket['description'] as String,
                                            style: const TextStyle(
                                                color: AppColors.muted)),
                                        const Divider(height: 26),
                                        Text(
                                            'SLA ${ticket['sla_status']} · ${ticket['assignee'] == null ? 'PROWEM Support assigned' : (ticket['assignee'] as Map<String, dynamic>)['name']}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        if (ticket['affected_service'] != null)
                                          Text(
                                              'Service: ${ticket['affected_service']}',
                                              style: const TextStyle(
                                                  color: AppColors.muted)),
                                        if (resolved &&
                                            ticket['resolution'] != null) ...[
                                          const SizedBox(height: 10),
                                          Text('✓ ${ticket['resolution']}',
                                              style: const TextStyle(
                                                  color: AppColors.lime,
                                                  fontWeight: FontWeight.w700))
                                        ],
                                      ])),
                              const SizedBox(height: 12),
                              _TicketFacts(ticket: ticket),
                              if (supportUser) ...[
                                const SizedBox(height: 12),
                                _SupportTicketControls(
                                  ticket: ticket,
                                  staff: (lookups['staff'] as List<dynamic>?) ??
                                      const [],
                                  saving: updating,
                                  onSubmit: updateTicket,
                                ),
                              ],
                              const SizedBox(height: 20),
                              const Text('CONVERSATION',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1)),
                              const SizedBox(height: 10),
                              if (messages.isEmpty)
                                const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                        child: Text(
                                            'No customer-visible messages yet.',
                                            style: TextStyle(
                                                color: AppColors.muted)))),
                              ...messages.map((raw) {
                                final item = raw as Map<String, dynamic>;
                                final author =
                                    item['author'] as Map<String, dynamic>?;
                                final outgoing = author?['role'] == 'organizer';
                                return Align(
                                    alignment: outgoing
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(12),
                                        constraints:
                                            const BoxConstraints(maxWidth: 320),
                                        decoration: BoxDecoration(
                                            color: outgoing
                                                ? const Color(0x1FFF6B3D)
                                                : AppColors.surface,
                                            border: Border.all(
                                                color: outgoing
                                                    ? const Color(0x55FF6B3D)
                                                    : AppColors.border),
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  outgoing
                                                      ? 'You'
                                                      : author?['name']
                                                              as String? ??
                                                          'PROWEM Support',
                                                  style: TextStyle(
                                                      color: outgoing
                                                          ? AppColors.coral
                                                          : AppColors.purple,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              const SizedBox(height: 5),
                                              Text(item['body'] as String)
                                            ])));
                              }),
                            ]))),
                if (sendError != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Text(sendError!,
                          style: const TextStyle(color: AppColors.danger))),
                SafeArea(
                    top: false,
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: TextField(
                                      controller: input,
                                      enabled: !sending,
                                      minLines: 1,
                                      maxLines: 4,
                                      textInputAction: TextInputAction.newline,
                                      decoration: const InputDecoration(
                                          hintText: 'Write a message…'))),
                              const SizedBox(width: 8),
                              IconButton(
                                  onPressed: sending ? null : send,
                                  tooltip: 'Send message',
                                  icon: sending
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.send,
                                          color: AppColors.coral))
                            ]))),
              ]);
            }),
        bottomNavigationBar: EventNavigationBar(
          eventId: widget.eventId,
          repository: widget.repository,
          selectedIndex: 4,
        ),
      );
}

class _TicketFacts extends StatelessWidget {
  const _TicketFacts({required this.ticket});

  final Map<String, dynamic> ticket;

  @override
  Widget build(BuildContext context) {
    final assignee = ticket['assignee'] as Map<String, dynamic>?;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        _TicketFact(
          icon: Icons.warning_amber_rounded,
          label: 'Issue',
          value: ticket['subject'] as String,
        ),
        _TicketFact(
          icon: Icons.location_on_outlined,
          label: 'Location',
          value: ticket['location'] as String? ?? 'Event wide',
        ),
        _TicketFact(
          icon: Icons.support_agent_rounded,
          label: 'Assignment',
          value: assignee == null
              ? 'Awaiting PROWEM assignment'
              : '${assignee['name']} assigned',
        ),
        _TicketFact(
          icon: Icons.timer_outlined,
          label: 'SLA status',
          value: _humanize('${ticket['sla_status']}'),
          color: ticket['sla_status'] == 'breached'
              ? AppColors.danger
              : AppColors.purple,
          last: true,
        ),
      ]),
    );
  }
}

class _TicketFact extends StatelessWidget {
  const _TicketFact({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.muted,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 11),
          SizedBox(
            width: 88,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

class _SupportTicketControls extends StatefulWidget {
  const _SupportTicketControls({
    required this.ticket,
    required this.staff,
    required this.saving,
    required this.onSubmit,
  });

  final Map<String, dynamic> ticket;
  final List<dynamic> staff;
  final bool saving;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;

  @override
  State<_SupportTicketControls> createState() => _SupportTicketControlsState();
}

class _SupportTicketControlsState extends State<_SupportTicketControls> {
  late String priority;
  late String status;
  late int? assigneeId;
  late final TextEditingController resolution;
  String? validationError;

  @override
  void initState() {
    super.initState();
    _sync();
    resolution =
        TextEditingController(text: widget.ticket['resolution'] as String?);
  }

  void _sync() {
    priority = widget.ticket['priority'] as String;
    status = widget.ticket['status'] as String;
    assigneeId =
        (widget.ticket['assignee'] as Map<String, dynamic>?)?['id'] as int?;
  }

  @override
  void didUpdateWidget(covariant _SupportTicketControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket['updated_at'] != widget.ticket['updated_at']) {
      _sync();
      resolution.text = widget.ticket['resolution'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    resolution.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (status == 'resolved' && resolution.text.trim().isEmpty) {
      setState(() => validationError = 'Add a resolution before resolving.');
      return;
    }
    setState(() => validationError = null);
    final originalStatus = widget.ticket['status'] as String;
    await widget.onSubmit({
      'priority': priority,
      'assignee_id': assigneeId,
      if (status != originalStatus) 'status': status,
      if (resolution.text.trim().isNotEmpty)
        'resolution': resolution.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final transitions = _ticketTransitions(widget.ticket['status'] as String);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: .07),
        border: Border.all(color: AppColors.purple.withValues(alpha: .32)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(children: [
            Icon(Icons.admin_panel_settings_outlined, color: AppColors.purple),
            SizedBox(width: 9),
            Text('PROWEM SUPPORT CONTROLS',
                style: TextStyle(
                    color: AppColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8)),
          ]),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const ['p1', 'p2', 'p3', 'p4']
                .map((value) => DropdownMenuItem(
                    value: value, child: Text(value.toUpperCase())))
                .toList(),
            onChanged: widget.saving
                ? null
                : (value) => setState(() => priority = value!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: assigneeId,
            decoration: const InputDecoration(labelText: 'Assigned to'),
            items: [
              const DropdownMenuItem<int?>(
                  value: null, child: Text('Unassigned')),
              ...widget.staff.map((raw) {
                final person = raw as Map<String, dynamic>;
                return DropdownMenuItem<int?>(
                    value: person['id'] as int,
                    child: Text(person['name'] as String));
              }),
            ],
            onChanged: widget.saving
                ? null
                : (value) => setState(() => assigneeId = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: transitions
                .map((value) => DropdownMenuItem(
                    value: value, child: Text(_humanize(value))))
                .toList(),
            onChanged: widget.saving
                ? null
                : (value) => setState(() => status = value!),
          ),
          if (status == 'resolved') ...[
            const SizedBox(height: 10),
            TextField(
              controller: resolution,
              enabled: !widget.saving,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Resolution',
                  hintText: 'Streaming restored and verified.'),
            ),
          ],
          if (validationError != null) ...[
            const SizedBox(height: 8),
            Text(validationError!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: widget.saving ? null : _save,
            icon: widget.saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(widget.saving ? 'Updating…' : 'Update ticket'),
          ),
        ],
      ),
    );
  }
}

List<String> _ticketTransitions(String status) => [
      status,
      ...switch (status) {
        'open' => ['in_progress', 'waiting', 'resolved'],
        'in_progress' => ['waiting', 'resolved'],
        'waiting' => ['in_progress', 'resolved'],
        'resolved' => ['reopened'],
        'reopened' => ['in_progress', 'resolved'],
        _ => <String>[],
      },
    ];

String _humanize(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)));
}
