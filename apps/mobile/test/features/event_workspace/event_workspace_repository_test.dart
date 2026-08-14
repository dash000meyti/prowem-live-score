import 'dart:convert';

import 'package:event_care_mobile/core/network/api_client.dart';
import 'package:event_care_mobile/features/event_workspace/data/event_workspace_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('critical mutations use the backend vertical-slice routes', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
          jsonEncode(
              {'success': true, 'message': null, 'data': <String, dynamic>{}}),
          200,
          headers: {'content-type': 'application/json'});
    });
    final repository = EventWorkspaceRepository(ApiClient(
        baseUrl: 'https://event-care.test/api/v1',
        token: 'token',
        client: client));

    await repository.completeTeamOperation(7, 11, 'verify_payment');
    await repository.transitionEvent(7, 'live');
    await repository.updateIncident(23, 'resolved',
        resolution: 'Backup referee confirmed.');

    expect(requests.map((request) => '${request.method} ${request.url.path}'), [
      'POST /api/v1/events/7/teams/11/actions/verify_payment',
      'PATCH /api/v1/events/7/status',
      'PATCH /api/v1/incidents/23',
    ]);
    expect(jsonDecode(requests[1].body), {'status': 'live'});
    expect(jsonDecode(requests[2].body),
        {'status': 'resolved', 'resolution': 'Backup referee confirmed.'});
  });
}
