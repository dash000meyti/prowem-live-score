import 'package:flutter/foundation.dart';

import '../../domain/entities/event_card.dart';
import '../../domain/repositories/events_repository.dart';

class EventsController extends ChangeNotifier {
  EventsController(this._repository);
  final EventsRepository _repository;

  String filter = 'all';
  bool isLoading = false;
  String? errorMessage;
  EventSummary summary = const EventSummary({});
  List<EventCard> events = const [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final values = await Future.wait([_repository.getSummary(), _repository.getEvents(filter: filter)]);
      summary = values[0] as EventSummary;
      events = values[1] as List<EventCard>;
    } catch (_) {
      errorMessage = 'Unable to load your events.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFilter(String value) async {
    filter = value;
    await load();
  }
}
