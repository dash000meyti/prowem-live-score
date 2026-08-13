import '../../../core/network/api_client.dart';

class EventWorkspaceRepository {
  const EventWorkspaceRepository(this.client);
  final ApiClient client;

  Future<Map<String, dynamic>> overview(int eventId) async => (await client.get('/events/$eventId/care'))['data'] as Map<String, dynamic>;
  Future<Map<String, dynamic>> readiness(int eventId) async => (await client.get('/events/$eventId/readiness'))['data'] as Map<String, dynamic>;
  Future<List<dynamic>> teams(int eventId) async => (await client.get('/events/$eventId/teams/readiness', query: {'per_page': '100'}))['data'] as List<dynamic>;
  Future<Map<String, dynamic>> live(int eventId) async => (await client.get('/events/$eventId/live'))['data'] as Map<String, dynamic>;
  Future<List<dynamic>> incidents(int eventId) async => (await client.get('/events/$eventId/incidents', query: {'per_page': '100'}))['data'] as List<dynamic>;
  Future<List<dynamic>> tickets(int eventId) async => (await client.get('/events/$eventId/tickets', query: {'per_page': '100'}))['data'] as List<dynamic>;
  Future<Map<String, dynamic>> supportHome(int eventId) async => (await client.get('/events/$eventId/support-home'))['data'] as Map<String, dynamic>;
  Future<List<dynamic>> activity(int eventId) async => (await client.get('/events/$eventId/activity', query: {'per_page': '100'}))['data'] as List<dynamic>;
  Future<Map<String, dynamic>> report(int eventId) async => (await client.get('/events/$eventId/care-report'))['data'] as Map<String, dynamic>;
  Future<Map<String, dynamic>> dimension(int eventId, String dimension) async => (await client.get('/events/$eventId/readiness/$dimension'))['data'] as Map<String, dynamic>;
  Future<Map<String, dynamic>> team(int eventId, int teamId) async => (await client.get('/events/$eventId/teams/$teamId/readiness'))['data'] as Map<String, dynamic>;
  Future<Map<String, dynamic>> incident(int incidentId) async => (await client.get('/incidents/$incidentId'))['data'] as Map<String, dynamic>;
  Future<Map<String, dynamic>> ticket(int ticketId) async => (await client.get('/tickets/$ticketId'))['data'] as Map<String, dynamic>;
  Future<List<dynamic>> ticketMessages(int ticketId) async => (await client.get('/tickets/$ticketId/messages', query: {'per_page': '100'}))['data'] as List<dynamic>;
  Future<void> createIncident(int eventId, Map<String, dynamic> body) async { await client.post('/events/$eventId/incidents', body: body); }
  Future<void> createTicket(int eventId, Map<String, dynamic> body) async { await client.post('/events/$eventId/tickets', body: body); }
  Future<void> sendTicketMessage(int ticketId, String body) async { await client.post('/tickets/$ticketId/messages', body: {'body': body}); }
  Future<List<dynamic>> notifications() async => (await client.get('/notifications', query: {'per_page': '100'}))['data'] as List<dynamic>;
  Future<void> readNotification(String id) async { await client.patch('/notifications/$id/read'); }
  Future<void> readAllNotifications() async { await client.post('/notifications/read-all'); }
}
