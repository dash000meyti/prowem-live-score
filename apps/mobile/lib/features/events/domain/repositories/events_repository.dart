import '../entities/event_card.dart';

abstract interface class EventsRepository {
  Future<EventSummary> getSummary();
  Future<List<EventCard>> getEvents(
      {String filter = 'all', String search = ''});
}
