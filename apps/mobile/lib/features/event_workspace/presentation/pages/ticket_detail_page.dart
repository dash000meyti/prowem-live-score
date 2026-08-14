import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/event_workspace_repository.dart';

class TicketDetailPage extends StatefulWidget {
  const TicketDetailPage(
      {required this.ticketId, required this.repository, super.key});
  final int ticketId;
  final EventWorkspaceRepository repository;
  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final input = TextEditingController();
  late Future<(Map<String, dynamic>, List<dynamic>)> loader = _load();
  bool sending = false;
  String? sendError;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !sending) reload();
    });
  }

  Future<(Map<String, dynamic>, List<dynamic>)> _load() async => (
        await widget.repository.ticket(widget.ticketId),
        await widget.repository.ticketMessages(widget.ticketId)
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
        body: FutureBuilder<(Map<String, dynamic>, List<dynamic>)>(
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
              final resolved = ticket['status'] == 'resolved';
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
                                        Wrap(spacing: 6, runSpacing: 6, children: [
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
      );
}

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
