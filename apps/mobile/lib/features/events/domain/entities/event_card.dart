class EventCard {
  const EventCard({required this.id, required this.reference, required this.name, required this.status, required this.startsAt, required this.endsAt, required this.venue, required this.readinessScore, required this.readinessStatus, required this.criticalBlockers, required this.openIncidents, required this.criticalIncidents, required this.openTickets});

  final int id;
  final String? reference;
  final String name;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? venue;
  final int readinessScore;
  final String readinessStatus;
  final int criticalBlockers;
  final int openIncidents;
  final int criticalIncidents;
  final int openTickets;
}

class EventSummary {
  const EventSummary(this.counts);
  final Map<String, int> counts;
  int operator [](String key) => counts[key] ?? 0;
}
