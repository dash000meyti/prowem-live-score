import 'package:flutter/material.dart';

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
        appBar: AppBar(title: const Text('Notifications'), actions: [
          TextButton(
              onPressed: () async {
                await widget.repository.readAllNotifications();
                _reload();
              },
              child: const Text('Read all'))
        ]),
        body: FutureBuilder<List<dynamic>>(
            future: _loader,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
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
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item =
                            snapshot.data![index] as Map<String, dynamic>;
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
