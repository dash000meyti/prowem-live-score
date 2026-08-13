import '../../domain/entities/event_card.dart';

class EventCardModel extends EventCard {
  const EventCardModel({required super.id, required super.reference, required super.name, required super.status, required super.startsAt, required super.endsAt, required super.venue, required super.readinessScore, required super.readinessStatus, required super.criticalBlockers, required super.openIncidents, required super.criticalIncidents, required super.openTickets});

  factory EventCardModel.fromJson(Map<String, dynamic> json) {
    final readiness = json['readiness'] as Map<String, dynamic>;
    final venue = json['venue'] as Map<String, dynamic>?;
    return EventCardModel(
      id: json['id'] as int,
      reference: json['external_reference'] as String?,
      name: json['name'] as String,
      status: json['status'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      venue: venue?['name'] as String?,
      readinessScore: readiness['score'] as int,
      readinessStatus: readiness['status'] as String,
      criticalBlockers: readiness['critical_blockers_count'] as int,
      openIncidents: json['open_incidents_count'] as int,
      criticalIncidents: json['critical_incidents_count'] as int,
      openTickets: json['open_tickets_count'] as int,
    );
  }
}
