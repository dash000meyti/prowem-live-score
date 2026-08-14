import 'package:flutter/material.dart';

import '../../data/event_workspace_repository.dart';
import '../resource_mode.dart';

class CreateResourcePage extends StatefulWidget {
  const CreateResourcePage(
      {required this.mode,
      required this.eventId,
      required this.repository,
      super.key});
  final ResourceMode mode;
  final int eventId;
  final EventWorkspaceRepository repository;
  @override
  State<CreateResourcePage> createState() => _CreateResourcePageState();
}

class _CreateResourcePageState extends State<CreateResourcePage> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      if (widget.mode == ResourceMode.incidents) {
        await widget.repository.createIncident(widget.eventId, {
          'type': 'operational',
          'category': 'other',
          'severity': 'medium',
          'title': title.text.trim(),
          'description': description.text.trim()
        });
      } else {
        await widget.repository.createTicket(widget.eventId, {
          'category': 'technical_help',
          'requested_urgency': 'normal',
          'subject': title.text.trim(),
          'description': description.text.trim()
        });
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.mode == ResourceMode.incidents
                ? 'Report incident'
                : 'Request support')),
        body: Form(
            key: formKey,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              TextFormField(
                  controller: title,
                  decoration: InputDecoration(
                      labelText: widget.mode == ResourceMode.incidents
                          ? 'Incident title'
                          : 'Subject'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Required'
                      : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: description,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.trim().length < 5
                      ? 'Add more detail'
                      : null),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: loading ? null : submit,
                  child: Text(loading ? 'Submitting…' : 'Submit')),
            ])),
      );
}
