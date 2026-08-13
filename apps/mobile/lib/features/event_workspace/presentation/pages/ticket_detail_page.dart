import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/event_workspace_repository.dart';

class TicketDetailPage extends StatefulWidget {
  const TicketDetailPage({required this.ticketId, required this.repository, super.key});
  final int ticketId;
  final EventWorkspaceRepository repository;
  @override State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final input = TextEditingController();
  late Future<List<dynamic>> messages = widget.repository.ticketMessages(widget.ticketId);
  @override void dispose() { input.dispose(); super.dispose(); }
  void reload() => setState(() => messages = widget.repository.ticketMessages(widget.ticketId));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ticket conversation')),
    body: Column(children: [
      Expanded(child: FutureBuilder<List<dynamic>>(future: messages, builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: snapshot.data!.length, itemBuilder: (context, index) {
          final item = snapshot.data![index] as Map<String, dynamic>;
          final author = item['author'] as Map<String, dynamic>?;
          return Align(alignment: author?['role'] == 'organizer' ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), constraints: const BoxConstraints(maxWidth: 320), decoration: BoxDecoration(color: author?['role'] == 'organizer' ? const Color(0x1FFF6B3D) : AppColors.surface, border: Border.all(color: author?['role'] == 'organizer' ? const Color(0x55FF6B3D) : AppColors.border), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(author?['name'] as String? ?? 'System', style: const TextStyle(color: AppColors.coral, fontSize: 12)), const SizedBox(height: 5), Text(item['body'] as String)])));
        });
      })),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: input, decoration: const InputDecoration(hintText: 'Write a message'))), IconButton(onPressed: () async { if (input.text.trim().isEmpty) return; await widget.repository.sendTicketMessage(widget.ticketId, input.text.trim()); input.clear(); reload(); }, icon: const Icon(Icons.send, color: AppColors.coral))]))),
    ]),
  );
}
