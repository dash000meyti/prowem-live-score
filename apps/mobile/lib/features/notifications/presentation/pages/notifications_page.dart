import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../event_workspace/data/event_workspace_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({required this.repository, super.key});
  final EventWorkspaceRepository repository;
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<dynamic>> _loader = widget.repository.notifications();
  void _reload() => setState(() => _loader = widget.repository.notifications());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: FutureBuilder<List<dynamic>>(
            future: _loader,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final error = snapshot.error;
                final expired =
                    error is AppException && error.code == 'AUTH_REQUIRED';
                return _NotificationsError(
                    message: expired
                        ? 'Your session has expired. Please sign in again.'
                        : '$error',
                    sessionExpired: expired,
                    retry: _reload,
                    signIn: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('You are all caught up.',
                        style: TextStyle(color: AppColors.muted)));
              }
              return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                await widget.repository.readAllNotifications();
                                _reload();
                              },
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Mark all as read'),
                            ),
                          );
                        }
                        final item =
                            snapshot.data![index - 1] as Map<String, dynamic>;
                        final unread = item['read_at'] == null;
                        return Card(
                            child: ListTile(
                                onTap: () async {
                                  if (unread) {
                                    await widget.repository
                                        .readNotification(item['id'] as String);
                                    _reload();
                                  }
                                },
                                leading: CircleAvatar(
                                    backgroundColor: unread
                                        ? const Color(0x26FF6B3D)
                                        : const Color(0xFF252B31),
                                    child: Icon(Icons.notifications_none,
                                        color: unread
                                            ? AppColors.coral
                                            : AppColors.muted)),
                                title: Text(item['title'] as String? ??
                                    'Event Care update'),
                                subtitle: Text(item['body'] as String? ?? ''),
                                trailing: unread
                                    ? const Icon(Icons.circle,
                                        size: 9, color: AppColors.coral)
                                    : null));
                      }));
            }),
      );
}

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(sessionExpired ? Icons.lock_clock : Icons.notifications_off,
                color: sessionExpired ? AppColors.warning : AppColors.coral,
                size: 42),
            const SizedBox(height: 14),
            Text(
                sessionExpired
                    ? 'Sign in required'
                    : 'Unable to load notifications',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: sessionExpired ? signIn : retry,
              child: Text(sessionExpired ? 'Sign in again' : 'Try again'),
            ),
          ]),
        ),
      );
}
