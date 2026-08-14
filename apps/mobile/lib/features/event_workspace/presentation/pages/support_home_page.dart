import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/event_workspace_repository.dart';
import '../resource_mode.dart';
import 'create_resource_page.dart';
import 'resource_list_page.dart';
import 'ticket_detail_page.dart';

class SupportHomePage extends StatefulWidget {
  const SupportHomePage(
      {required this.eventId, required this.repository, super.key});
  final int eventId;
  final EventWorkspaceRepository repository;
  @override
  State<SupportHomePage> createState() => _SupportHomePageState();
}

class _SupportHomePageState extends State<SupportHomePage> {
  late Future<Map<String, dynamic>> loader =
      widget.repository.supportHome(widget.eventId);
  void reload() =>
      setState(() => loader = widget.repository.supportHome(widget.eventId));

  void ticket(int id) => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          TicketDetailPage(ticketId: id, repository: widget.repository)));
  Future<void> create() async {
    final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
            builder: (_) => CreateResourcePage(
                mode: ResourceMode.tickets,
                eventId: widget.eventId,
                repository: widget.repository)));
    if (created == true) reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const _SupportBrand(), actions: [
          OutlinedButton.icon(
              onPressed: create,
              icon: const Icon(Icons.headset_mic_outlined),
              label: const Text('Contact PROWEM')),
          const SizedBox(width: 12)
        ]),
        body: FutureBuilder<Map<String, dynamic>>(
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
              final data = snapshot.data!;
              final critical = data['critical'] as Map<String, dynamic>?;
              final open = data['open'] as List<dynamic>;
              final resolved = data['resolved'] as List<dynamic>;
              final counts = data['counts'] as Map<String, dynamic>;
              return RefreshIndicator(
                  onRefresh: () async {
                    reload();
                    await loader;
                  },
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        if (critical != null)
                          _CriticalTicket(
                              ticket: critical,
                              onOpen: () => ticket(critical['id'] as int))
                        else
                          const _SupportClear(),
                        const SizedBox(height: 28),
                        _Section(
                            title: 'Other open requests',
                            total: counts['open'] as int,
                            children: open.take(5).map((item) {
                              final value = item as Map<String, dynamic>;
                              return _TicketRow(
                                  ticket: value,
                                  onTap: () => ticket(value['id'] as int));
                            }).toList()),
                        const SizedBox(height: 26),
                        _Section(
                            title: 'Resolved',
                            total: counts['resolved'] as int,
                            children: resolved.take(5).map((item) {
                              final value = item as Map<String, dynamic>;
                              return _TicketRow(
                                  ticket: value,
                                  resolved: true,
                                  onTap: () => ticket(value['id'] as int));
                            }).toList()),
                      ]));
            }),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
                height: 66,
                decoration: const BoxDecoration(
                    color: Color(0xF205070A),
                    border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavIcon(Icons.home_outlined, 'Home',
                          onTap: () => Navigator.pop(context)),
                      _NavIcon(Icons.calendar_month_outlined, 'Events',
                          onTap: () => Navigator.popUntil(
                              context, (route) => route.isFirst)),
                      _NavIcon(Icons.sports_soccer, 'Live',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => ResourceListPage(
                                      title: 'Live control',
                                      loader: widget.repository
                                          .live(widget.eventId),
                                      mode: ResourceMode.live,
                                      eventId: widget.eventId,
                                      repository: widget.repository)))),
                      _NavIcon(Icons.chat_bubble_outline, 'Updates',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => ResourceListPage(
                                      title: 'Activity',
                                      loader: widget.repository
                                          .activity(widget.eventId),
                                      mode: ResourceMode.activity,
                                      eventId: widget.eventId,
                                      repository: widget.repository)))),
                      const _NavIcon(Icons.headset_mic, 'Support', active: true)
                    ]))),
      );
}

class _SupportBrand extends StatelessWidget {
  const _SupportBrand();
  @override
  Widget build(BuildContext context) =>
      const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shield_outlined, color: AppColors.coral),
        SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PROWEM',
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
          Text('EVENT CARE',
              style: TextStyle(
                  color: AppColors.coral,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 1.1))
        ])
      ]);
}

class _CriticalTicket extends StatelessWidget {
  const _CriticalTicket({required this.ticket, required this.onOpen});
  final Map<String, dynamic> ticket;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.danger),
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x663E0A0F), Color(0xFF080A0D)]),
          boxShadow: const [
            BoxShadow(color: Color(0x33FF3B4E), blurRadius: 30)
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.notification_important_outlined,
              color: AppColors.danger, size: 31),
          const SizedBox(width: 10),
          const Expanded(
              child: Text('CRITICAL SUPPORT ACTIVE',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 20,
                      fontWeight: FontWeight.w900))),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('${ticket['priority']}'.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 23, fontWeight: FontWeight.w900)))
        ]),
        const SizedBox(height: 18),
        const Divider(),
        _CriticalDetail(
            icon: Icons.warning_amber,
            label: 'ISSUE',
            value: ticket['subject'] as String),
        _CriticalDetail(
            icon: Icons.location_on,
            label: 'LOCATION',
            value: ticket['location'] as String? ?? 'Event wide'),
        _CriticalDetail(
            icon: Icons.groups,
            label: 'ASSIGNMENT',
            value: ticket['assignee'] == null
                ? 'PROWEM Support assigned'
                : '${(ticket['assignee'] as Map<String, dynamic>)['name']} assigned'),
        _CriticalDetail(
            icon: Icons.timer_outlined,
            label: 'SLA STATUS',
            value: _sla(ticket),
            danger: true),
        const SizedBox(height: 14),
        FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.confirmation_number),
            label: const Text('Open Ticket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))
      ]));
}

class _CriticalDetail extends StatelessWidget {
  const _CriticalDetail(
      {required this.icon,
      required this.label,
      required this.value,
      this.danger = false});
  final IconData icon;
  final String label;
  final String value;
  final bool danger;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border)),
            child: Icon(icon,
                color: danger ? AppColors.danger : Colors.white70, size: 20)),
        const SizedBox(width: 12),
        SizedBox(
            width: 95,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700))),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    color: danger ? AppColors.danger : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)))
      ]));
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.total, required this.children});
  final String title;
  final int total;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w800))),
          Text('$total total', style: const TextStyle(color: AppColors.coral))
        ]),
        const SizedBox(height: 10),
        if (children.isEmpty)
          const _Empty()
        else
          ...children.map((child) =>
              Padding(padding: const EdgeInsets.only(bottom: 8), child: child))
      ]);
}

class _TicketRow extends StatelessWidget {
  const _TicketRow(
      {required this.ticket, required this.onTap, this.resolved = false});
  final Map<String, dynamic> ticket;
  final VoidCallback onTap;
  final bool resolved;
  @override
  Widget build(BuildContext context) {
    final priority = ticket['priority'] as String;
    final tone = resolved ? AppColors.lime : _priority(priority);
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: tone.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(resolved ? 26 : 10)),
                  child: resolved
                      ? const Icon(Icons.check, color: AppColors.lime, size: 29)
                      : Text(priority.toUpperCase(),
                          style: TextStyle(
                              color: tone,
                              fontSize: 18,
                              fontWeight: FontWeight.w900))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(ticket['subject'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(
                        ticket['location'] as String? ??
                            ticket['description'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted))
                  ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        border: Border.all(color: tone),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(
                        resolved
                            ? 'RESOLVED'
                            : '${ticket['status']}'
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                        style: TextStyle(
                            color: tone,
                            fontSize: 10,
                            fontWeight: FontWeight.w800))),
                const SizedBox(height: 8),
                Text(
                    _age(resolved
                        ? ticket['resolved_at'] as String?
                        : ticket['updated_at'] as String?),
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 11))
              ]),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.muted)
            ])));
  }
}

class _SupportClear extends StatelessWidget {
  const _SupportClear();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18)),
      child: const Row(children: [
        CircleAvatar(
            backgroundColor: Color(0x2239FF6A),
            child: Icon(Icons.check, color: AppColors.lime)),
        SizedBox(width: 14),
        Expanded(
            child: Text('No critical support active',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)))
      ]));
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Container(
      height: 82,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(15)),
      child: const Text('Nothing to show.',
          style: TextStyle(color: AppColors.muted)));
}

class _NavIcon extends StatelessWidget {
  const _NavIcon(this.icon, this.label, {this.active = false, this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: active ? AppColors.coral : AppColors.muted),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: active ? AppColors.coral : AppColors.muted,
                    fontSize: 11))
          ])));
}

Color _priority(String priority) => switch (priority) {
      'p1' => AppColors.danger,
      'p2' => AppColors.orange,
      'p3' => AppColors.warning,
      _ => AppColors.cyan
    };
String _sla(Map<String, dynamic> ticket) {
  if (ticket['sla_status'] == 'breached') return 'SLA breached';
  if (ticket['first_response_at'] != null) return 'Response received';
  final minutes = ((ticket['sla_remaining_seconds'] as num) / 60).ceil();
  return 'SLA $minutes min remaining';
}

String _age(String? value) {
  if (value == null) return '';
  final difference = DateTime.now().difference(DateTime.parse(value).toLocal());
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} h ago';
  return '${difference.inDays} d ago';
}
