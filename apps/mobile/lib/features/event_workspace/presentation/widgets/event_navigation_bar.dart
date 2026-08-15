import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/event_workspace_repository.dart';
import '../pages/resource_list_page.dart';
import '../pages/support_home_page.dart';
import '../resource_mode.dart';

const eventsRouteName = '/events';

class EventNavigationBar extends StatelessWidget {
  const EventNavigationBar({
    required this.eventId,
    required this.repository,
    required this.selectedIndex,
    this.replaceCurrent = true,
    super.key,
  });

  final int eventId;
  final EventWorkspaceRepository repository;
  final int selectedIndex;
  final bool replaceCurrent;

  void _select(BuildContext context, int index) {
    if (index == 0) {
      Navigator.of(context).popUntil(
        (route) => route.settings.name == eventsRouteName || route.isFirst,
      );
      return;
    }
    if (index == selectedIndex) return;

    final Widget page = switch (index) {
      1 => ResourceListPage(
          title: 'Event checklists',
          loader: repository.readiness(eventId),
          mode: ResourceMode.readiness,
          eventId: eventId,
          repository: repository,
        ),
      2 => ResourceListPage(
          title: 'Matches',
          loader: repository.live(eventId),
          mode: ResourceMode.live,
          eventId: eventId,
          repository: repository,
        ),
      3 => ResourceListPage(
          title: 'Teams',
          loader: repository.teams(eventId),
          mode: ResourceMode.teams,
          eventId: eventId,
          repository: repository,
        ),
      _ => SupportHomePage(eventId: eventId, repository: repository),
    };
    final route = MaterialPageRoute<void>(builder: (_) => page);
    if (replaceCurrent) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xF205070A),
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: NavigationBar(
            height: 68,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _select(context, index),
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0x26FF6B3D),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.coral),
                label: 'My Events',
              ),
              NavigationDestination(
                  icon: Icon(Icons.checklist), label: 'Tasks'),
              NavigationDestination(
                  icon: Icon(Icons.sports_soccer), label: 'Matches'),
              NavigationDestination(
                  icon: Icon(Icons.groups_outlined), label: 'People'),
              NavigationDestination(
                  icon: Icon(Icons.headset_mic_outlined), label: 'Support'),
            ],
          ),
        ),
      );
}
