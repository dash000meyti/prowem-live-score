import '../../domain/entities/event_card.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources/events_remote_data_source.dart';

class EventsRepositoryImpl implements EventsRepository {
  const EventsRepositoryImpl(this.remote);
  final EventsRemoteDataSource remote;

  @override
  Future<List<EventCard>> getEvents({String filter = 'all', String search = ''}) => remote.getEvents(filter: filter, search: search);

  @override
  Future<EventSummary> getSummary() => remote.getSummary();
}
