import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../events/domain/entities/event_card.dart';
import '../../data/event_workspace_repository.dart';
import '../resource_mode.dart';
import 'resource_list_page.dart';
import 'support_home_page.dart';

class EventWorkspacePage extends StatefulWidget {
  const EventWorkspacePage({required this.event, required this.repository, super.key});
  final EventCard event;
  final EventWorkspaceRepository repository;

  @override
  State<EventWorkspacePage> createState() => _EventWorkspacePageState();
}

class _EventWorkspacePageState extends State<EventWorkspacePage> {
  late Future<Map<String, dynamic>> overview = widget.repository.overview(widget.event.id);

  void reload() => setState(() => overview = widget.repository.overview(widget.event.id));

  void open(String title, Future<Object> loader, ResourceMode mode) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ResourceListPage(title: title, loader: loader, mode: mode, eventId: widget.event.id, repository: widget.repository)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const _HeaderBrand(),
          actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh)), const SizedBox(width: 6)],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: overview,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _LoadError(message: '${snapshot.error}', retry: reload);
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async { reload(); await overview; },
              child: _EventHomeBody(event: widget.event, data: data, repository: widget.repository, open: open),
            );
          },
        ),
        bottomNavigationBar: _EventBottomNav(
          onSelect: (index) {
            if (index == 0) return;
            if (index == 1) open('Event checklists', widget.repository.readiness(widget.event.id), ResourceMode.readiness);
            if (index == 2) open('Matches', widget.repository.live(widget.event.id), ResourceMode.live);
            if (index == 3) open('Teams', widget.repository.teams(widget.event.id), ResourceMode.teams);
            if (index == 4) Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SupportHomePage(eventId: widget.event.id, repository: widget.repository)));
          },
        ),
      );
}

class _EventHomeBody extends StatelessWidget {
  const _EventHomeBody({required this.event, required this.data, required this.repository, required this.open});
  final EventCard event;
  final Map<String, dynamic> data;
  final EventWorkspaceRepository repository;
  final void Function(String, Future<Object>, ResourceMode) open;

  @override
  Widget build(BuildContext context) {
    final readiness = data['readiness'] as Map<String, dynamic>;
    final attention = data['needs_attention'] as List<dynamic>;
    final matches = data['next_matches'] as List<dynamic>;
    final activity = data['recent_activity'] as List<dynamic>;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _EventIdentity(event: event),
        const SizedBox(height: 18),
        _ReadinessHero(readiness: readiness),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Needs attention', label: 'View all (${attention.length})', onTap: () => open('Event checklists', repository.readiness(event.id), ResourceMode.readiness)),
        const SizedBox(height: 10),
        if (attention.isEmpty) const _EmptyCard(label: 'Everything is on track.') else ...attention.take(3).toList().asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 9), child: _AttentionCard(item: entry.value as Map<String, dynamic>, index: entry.key + 1, onTap: () { final item = entry.value as Map<String, dynamic>; open(_title(item['dimension']), repository.dimension(event.id, item['dimension'] as String), ResourceMode.readiness); }))),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Upcoming matches', label: 'Full schedule', onTap: () => open('Matches', repository.live(event.id), ResourceMode.live)),
        const SizedBox(height: 10),
        _GlassList(children: matches.isEmpty ? [const _EmptyRow(label: 'No upcoming matches.')] : matches.take(4).map((raw) => _MatchRow(match: raw as Map<String, dynamic>)).toList()),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Recent activity', label: 'View all', onTap: () => open('Activity', repository.activity(event.id), ResourceMode.activity)),
        const SizedBox(height: 10),
        _GlassList(children: activity.isEmpty ? [const _EmptyRow(label: 'No recent activity.')] : activity.take(5).map((raw) => _ActivityRow(item: raw as Map<String, dynamic>)).toList()),
      ],
    );
  }
}

class _HeaderBrand extends StatelessWidget {
  const _HeaderBrand();
  @override Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shield_outlined, color: AppColors.coral), SizedBox(width: 9), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('PROWEM', style: TextStyle(fontSize: 17, height: 1, fontWeight: FontWeight.w800, letterSpacing: 1.2)), Text('EVENT CARE', style: TextStyle(color: AppColors.coral, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.1))])]);
}

class _EventIdentity extends StatelessWidget {
  const _EventIdentity({required this.event}); final EventCard event;
  @override Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [_Crest(name: event.name), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.name, style: const TextStyle(fontSize: 27, height: 1.05, fontWeight: FontWeight.w800)), const SizedBox(height: 10), Row(children: [const Icon(Icons.location_on_outlined, size: 18, color: AppColors.muted), const SizedBox(width: 5), Expanded(child: Text(event.venue ?? 'Venue pending', style: const TextStyle(color: AppColors.muted)))]), const SizedBox(height: 6), Row(children: [const Icon(Icons.calendar_today_outlined, size: 17, color: AppColors.muted), const SizedBox(width: 6), Text(_dateRange(event.startsAt, event.endsAt), style: const TextStyle(color: AppColors.muted))])]))]);
}

class _Crest extends StatelessWidget {
  const _Crest({required this.name}); final String name;
  @override Widget build(BuildContext context) { final initials = name.split(' ').take(3).map((part) => part[0]).join(); return Container(width: 92, height: 106, decoration: BoxDecoration(border: Border.all(color: Colors.white70, width: 2), borderRadius: const BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(40)), gradient: const RadialGradient(colors: [Color(0x44FF6B3D), Color(0xFF0A1016)])), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('EVENT CARE', style: TextStyle(color: AppColors.coral, fontSize: 8, fontWeight: FontWeight.w700))])); }
}

class _ReadinessHero extends StatelessWidget {
  const _ReadinessHero({required this.readiness}); final Map<String, dynamic> readiness;
  @override Widget build(BuildContext context) { final status = readiness['status'] as String; final tone = status == 'blocked' ? AppColors.danger : status == 'warning' ? AppColors.warning : AppColors.lime; return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(border: Border.all(color: tone.withValues(alpha: .55)), borderRadius: BorderRadius.circular(18), gradient: LinearGradient(colors: [tone.withValues(alpha: .12), AppColors.surface]), boxShadow: [BoxShadow(color: tone.withValues(alpha: .1), blurRadius: 28)]), child: Row(children: [SizedBox(width: 116, height: 116, child: Stack(fit: StackFit.expand, children: [CircularProgressIndicator(value: (readiness['score'] as num) / 100, strokeWidth: 10, strokeCap: StrokeCap.round, backgroundColor: const Color(0xFF34373C), color: AppColors.warning), Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('${readiness['score']}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)), const Text('READINESS', style: TextStyle(color: AppColors.muted, fontSize: 10))]))])), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(border: Border.all(color: tone), borderRadius: BorderRadius.circular(999), color: tone.withValues(alpha: .1)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_outline, size: 17, color: tone), const SizedBox(width: 6), Flexible(child: Text(status.toUpperCase(), style: TextStyle(color: tone, fontWeight: FontWeight.w800)))])), const SizedBox(height: 18), Text('${readiness['critical_blockers_count']} critical blockers', style: const TextStyle(color: AppColors.danger, fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 10), Text('${readiness['actions_required_count']} actions required', style: const TextStyle(color: AppColors.warning, fontSize: 16, fontWeight: FontWeight.w700))]))])); }
}

class _SectionHeader extends StatelessWidget { const _SectionHeader({required this.title, required this.label, required this.onTap}); final String title; final String label; final VoidCallback onTap; @override Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))), TextButton(onPressed: onTap, child: Row(children: [Text(label), const SizedBox(width: 3), const Icon(Icons.chevron_right, size: 18)]))]); }

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.item, required this.index, required this.onTap}); final Map<String, dynamic> item; final int index; final VoidCallback onTap;
  @override Widget build(BuildContext context) { final critical = item['status'] == 'blocked' || item['is_critical'] == true; final tone = critical ? AppColors.danger : AppColors.warning; return Container(decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)), child: IntrinsicHeight(child: Row(children: [Container(width: 5, decoration: BoxDecoration(color: tone, borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)))), Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Stack(clipBehavior: Clip.none, children: [CircleAvatar(radius: 28, backgroundColor: tone.withValues(alpha: .14), child: Icon(_attentionIcon(item['dimension'] as String), color: tone)), Positioned(top: -6, left: -5, child: CircleAvatar(radius: 10, backgroundColor: tone, child: Text('$index', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800))))]), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(critical ? 'CRITICAL' : 'WARNING', style: TextStyle(color: tone, fontSize: 11, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(item['message'] as String? ?? _title(item['check_type']), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('${_title(item['dimension'])} requires attention.', style: const TextStyle(color: AppColors.muted, fontSize: 12))])), const SizedBox(width: 8), OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: tone, side: BorderSide(color: tone), padding: const EdgeInsets.symmetric(horizontal: 13)), child: Text(critical ? 'Resolve' : 'Review'))])))]))); }
}

class _GlassList extends StatelessWidget { const _GlassList({required this.children}); final List<Widget> children; @override Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)), child: Column(children: children.expand((child) sync* { if (child != children.first) yield const Divider(height: 1); yield child; }).toList())); }
class _MatchRow extends StatelessWidget { const _MatchRow({required this.match}); final Map<String, dynamic> match; @override Widget build(BuildContext context) { final home = match['home_team'] as Map<String, dynamic>?; final away = match['away_team'] as Map<String, dynamic>?; return Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), child: Row(children: [SizedBox(width: 58, child: Text(_time(match['kickoff_at'] as String), style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700))), Expanded(child: Text('${home?['name'] ?? 'TBC'}  vs  ${away?['name'] ?? 'TBC'}', maxLines: 2, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8), Text(match['field'] as String? ?? 'TBC', style: const TextStyle(color: AppColors.muted, fontSize: 12)), const Icon(Icons.chevron_right, color: AppColors.muted)])); } }
class _ActivityRow extends StatelessWidget { const _ActivityRow({required this.item}); final Map<String, dynamic> item; @override Widget build(BuildContext context) { final danger = '${item['type']}'.contains('incident') || '${item['type']}'.contains('issue'); final tone = danger ? AppColors.danger : AppColors.lime; return Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [CircleAvatar(radius: 20, backgroundColor: tone.withValues(alpha: .14), child: Icon(danger ? Icons.warning_amber : Icons.check, color: tone, size: 19)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['title'] as String? ?? 'Event update', maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 3), Text(item['description'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12))])), const SizedBox(width: 8), Text(_time(item['occurred_at'] as String), style: const TextStyle(color: AppColors.muted, fontSize: 12))])); } }
class _EmptyCard extends StatelessWidget { const _EmptyCard({required this.label}); final String label; @override Widget build(BuildContext context) => Container(height: 90, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)), child: Text(label, style: const TextStyle(color: AppColors.muted))); }
class _EmptyRow extends StatelessWidget { const _EmptyRow({required this.label}); final String label; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20), child: Text(label, style: const TextStyle(color: AppColors.muted))); }
class _LoadError extends StatelessWidget { const _LoadError({required this.message, required this.retry}); final String message; final VoidCallback retry; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, color: AppColors.danger, size: 42), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 18), FilledButton(onPressed: retry, child: const Text('Try again'))]))); }

class _EventBottomNav extends StatelessWidget { const _EventBottomNav({required this.onSelect}); final ValueChanged<int> onSelect; @override Widget build(BuildContext context) => SafeArea(top: false, child: Container(decoration: const BoxDecoration(color: Color(0xF205070A), border: Border(top: BorderSide(color: AppColors.border))), child: NavigationBar(height: 68, selectedIndex: 0, onDestinationSelected: onSelect, backgroundColor: Colors.transparent, indicatorColor: const Color(0x26FF6B3D), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.coral), label: 'Home'), NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'), NavigationDestination(icon: Icon(Icons.sports_soccer), label: 'Matches'), NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'People'), NavigationDestination(icon: Icon(Icons.headset_mic_outlined), label: 'Support')]))); }

IconData _attentionIcon(String dimension) => switch (dimension) { 'streaming' => Icons.sensors, 'teams' => Icons.credit_card, 'referees' => Icons.person_outline, _ => Icons.warning_amber };
String _title(Object? value) => '${value ?? 'Action required'}'.replaceAll('_', ' ').split(' ').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
String _time(String value) { final date = DateTime.parse(value).toLocal(); final hour = date.hour % 12 == 0 ? 12 : date.hour % 12; final minute = date.minute.toString().padLeft(2, '0'); return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}'; }
String _dateRange(DateTime from, DateTime to) => '${_months[from.month - 1]} ${from.day} – ${_months[to.month - 1]} ${to.day}, ${to.year}';
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
