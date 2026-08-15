import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/event_workspace_repository.dart';
import '../widgets/event_navigation_bar.dart';

class TeamPassportPage extends StatefulWidget {
  const TeamPassportPage(
      {required this.eventId,
      required this.teamId,
      required this.repository,
      super.key});

  final int eventId;
  final int teamId;
  final EventWorkspaceRepository repository;

  @override
  State<TeamPassportPage> createState() => _TeamPassportPageState();
}

class _TeamPassportPageState extends State<TeamPassportPage> {
  late Future<Map<String, dynamic>> _loader =
      widget.repository.team(widget.eventId, widget.teamId);
  String? _pendingOperation;
  String? _confirmingOperation;
  String? _error;
  String? _success;
  int? _currentScore;

  void _reload() => setState(
      () => _loader = widget.repository.team(widget.eventId, widget.teamId));

  Future<void> _run(Map<String, dynamic> check) async {
    final operation = check['action'] as String?;
    if (operation == null) return;
    setState(() {
      _pendingOperation = operation;
      _confirmingOperation = null;
      _error = null;
      _success = null;
    });
    try {
      final before = _currentScore;
      final updated = await widget.repository
          .completeTeamOperation(widget.eventId, widget.teamId, operation);
      if (!mounted) return;
      final after = updated['score'] as int;
      setState(() {
        _currentScore = after;
        _success =
            '${check['label']} completed. Team readiness${before == null ? '' : ' $before% →'} $after%. Event readiness recalculated.';
        _loader = Future.value(updated);
      });
      try {
        final fresh =
            await widget.repository.team(widget.eventId, widget.teamId);
        if (mounted) setState(() => _loader = Future.value(fresh));
      } catch (_) {
        // Keep the confirmed mutation response visible if reconciliation fails.
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _pendingOperation = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Team passport'), actions: [
          IconButton(
              onPressed: _pendingOperation == null ? _reload : null,
              icon: const Icon(Icons.refresh))
        ]),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _loader,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Error(message: '${snapshot.error}', retry: _reload);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            _currentScore = data['score'] as int;
            final team = data['team'] as Map<String, dynamic>;
            final manager = data['manager'] as Map<String, dynamic>;
            final firstMatch = data['first_match'] as Map<String, dynamic>?;
            final allChecks =
                (data['checks'] as List<dynamic>).cast<Map<String, dynamic>>();
            final checks =
                allChecks.where((check) => check['status'] != 'ready').toList();
            final completed =
                allChecks.where((check) => check['status'] == 'ready').toList();
            return RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _loader;
              },
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    Text(team['name'] as String,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(
                        'Manager: ${manager['name'] ?? 'Not assigned'}${manager['phone'] == null ? '' : ' · ${manager['phone']}'}',
                        style: const TextStyle(color: AppColors.muted)),
                    if (firstMatch != null) ...[
                      const SizedBox(height: 8),
                      Text(_firstMatchLabel(firstMatch),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15)),
                    ],
                    const SizedBox(height: 18),
                    _Summary(data: data),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: _error!)
                    ],
                    if (_success != null) ...[
                      const SizedBox(height: 12),
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.lime.withValues(alpha: .1),
                              border: Border.all(color: AppColors.lime),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text('✓ $_success',
                              style: const TextStyle(color: AppColors.lime)))
                    ],
                    const SizedBox(height: 22),
                    Text(checks.isNotEmpty ? 'NEEDS ATTENTION' : 'ALL READY',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1)),
                    const SizedBox(height: 10),
                    ...checks.map((raw) {
                      final check = raw;
                      final status = check['status'] as String;
                      final action = check['action'] as String?;
                      final actionable = status != 'ready' && action != null;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                    status == 'ready'
                                        ? Icons.check_circle
                                        : Icons.error_outline,
                                    color: _tone(status)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(check['label'] as String,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      if (check['message'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(check['message'] as String,
                                            style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 14,
                                                height: 1.35))
                                      ],
                                      if (actionable) ...[
                                        const SizedBox(height: 12),
                                        if (_confirmingOperation == action)
                                          _InlineConfirmation(
                                            label: _actionLabel(action),
                                            onCancel: () => setState(() =>
                                                _confirmingOperation = null),
                                            onConfirm: () => _run(check),
                                          )
                                        else
                                          SizedBox(
                                              width: double.infinity,
                                              child: FilledButton(
                                                  onPressed: _pendingOperation ==
                                                          null
                                                      ? () => setState(() =>
                                                          _confirmingOperation =
                                                              action)
                                                      : null,
                                                  child: _pendingOperation ==
                                                          action
                                                      ? const SizedBox.square(
                                                          dimension: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2))
                                                      : Text(_actionLabel(
                                                          action))))
                                      ],
                                    ])),
                                Text(status.toUpperCase(),
                                    style: TextStyle(
                                        color: _tone(status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ]),
                        ),
                      );
                    }),
                    if (completed.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _CompletedChecks(checks: completed),
                    ],
                  ]),
            );
          },
        ),
        bottomNavigationBar: EventNavigationBar(
          eventId: widget.eventId,
          repository: widget.repository,
          selectedIndex: 3,
        ),
      );
}

class _InlineConfirmation extends StatelessWidget {
  const _InlineConfirmation({
    required this.label,
    required this.onCancel,
    required this.onConfirm,
  });

  final String label;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.coral.withValues(alpha: .09),
          border: Border.all(color: AppColors.coral.withValues(alpha: .35)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Confirm $label?',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Readiness will update automatically.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  child: Text(label),
                ),
              ),
            ]),
          ],
        ),
      );
}

class _CompletedChecks extends StatelessWidget {
  const _CompletedChecks({required this.checks});

  final List<Map<String, dynamic>> checks;

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          leading: const Icon(Icons.check_circle, color: AppColors.lime),
          title: Text('Completed (${checks.length})'),
          subtitle: const Text('Tap to review'),
          children: checks
              .map((check) => ListTile(
                    leading: const Icon(Icons.check, color: AppColors.lime),
                    title: Text(check['label'] as String),
                    subtitle: check['message'] == null
                        ? null
                        : Text(check['message'] as String),
                  ))
              .toList(),
        ),
      );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: _tone(status)),
          borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Text('${data['score']}%',
            style: TextStyle(
                color: _tone(status),
                fontSize: 38,
                fontWeight: FontWeight.w900)),
        const SizedBox(width: 18),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(status.toUpperCase(),
              style:
                  TextStyle(color: _tone(status), fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(
              '${data['blockers_count']} blockers · ${data['actions_required_count']} actions',
              style: const TextStyle(color: AppColors.muted))
        ])),
      ]),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: retry, child: const Text('Try again'))
          ])));
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: .12),
          border: Border.all(color: AppColors.danger),
          borderRadius: BorderRadius.circular(12)),
      child: Text(message));
}

Color _tone(String status) => switch (status) {
      'ready' => AppColors.lime,
      'warning' => AppColors.warning,
      _ => AppColors.danger
    };
String _actionLabel(String operation) => operation
    .replaceAll('_', ' ')
    .split(' ')
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

String _firstMatchLabel(Map<String, dynamic> match) {
  final field = match['field'] as String?;
  final kickoff = DateTime.tryParse('${match['kickoff_at']}')?.toLocal();
  final time = kickoff == null
      ? null
      : '${kickoff.hour.toString().padLeft(2, '0')}:${kickoff.minute.toString().padLeft(2, '0')}';
  return [
    'First match',
    if (field != null) field,
    if (time != null) time,
  ].join(' · ');
}
