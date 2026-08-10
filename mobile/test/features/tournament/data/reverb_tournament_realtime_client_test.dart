import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/core/network/web_socket_transport.dart';
import 'package:prowem_live_score/features/tournament/data/reverb_tournament_realtime_client.dart';
import 'package:prowem_live_score/features/tournament/data/tournament_realtime_client.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';

void main() {
  group('ReverbTournamentRealtimeClient', () {
    test('connects using the expected Reverb/Pusher URI', () async {
      Uri? capturedUri;

      final transport = FakeWebSocketTransport();

      final client = ReverbTournamentRealtimeClient(
        host: 'localhost',
        port: 18081,
        appKey: 'test-key',
        useTls: false,
        transportFactory: (uri) {
          capturedUri = uri;
          return transport;
        },
      );

      addTearDown(client.dispose);

      await client.connect();

      expect(capturedUri, isNotNull);

      expect(capturedUri!.scheme, 'ws');

      expect(capturedUri!.host, 'localhost');

      expect(capturedUri!.port, 18081);

      expect(capturedUri!.path, '/app/test-key');

      expect(capturedUri!.queryParameters['protocol'], '7');
    });

    test('subscribes to tournament after Pusher handshake', () async {
      final transport = FakeWebSocketTransport();

      final client = ReverbTournamentRealtimeClient(
        host: 'localhost',
        port: 18081,
        appKey: 'test-key',
        useTls: false,
        transportFactory: (_) => transport,
      );

      addTearDown(client.dispose);

      final statuses = <RealtimeConnectionStatus>[];

      final statusSubscription = client.connectionStatuses.listen(statuses.add);

      addTearDown(statusSubscription.cancel);

      await client.connect();

      transport.serverSend({
        'event': 'pusher:connection_established',
        'data': jsonEncode({'socket_id': '123.456', 'activity_timeout': 30}),
      });

      await _flushEvents();

      expect(statuses, contains(RealtimeConnectionStatus.connected));

      expect(transport.sentMessages, hasLength(1));

      final subscribe =
          jsonDecode(transport.sentMessages.single) as Map<String, dynamic>;

      expect(subscribe['event'], 'pusher:subscribe');

      expect(subscribe['data'], {'channel': 'tournament'});
    });

    test('responds to pusher ping with pong', () async {
      final transport = FakeWebSocketTransport();

      final client = ReverbTournamentRealtimeClient(
        host: 'localhost',
        port: 18081,
        appKey: 'test-key',
        useTls: false,
        transportFactory: (_) => transport,
      );

      addTearDown(client.dispose);

      await client.connect();

      transport.serverSend({
        'event': 'pusher:connection_established',
        'data': '{}',
      });

      await _flushEvents();

      transport.sentMessages.clear();

      transport.serverSend({'event': 'pusher:ping', 'data': '{}'});

      await _flushEvents();

      expect(transport.sentMessages, hasLength(1));

      final pong =
          jsonDecode(transport.sentMessages.single) as Map<String, dynamic>;

      expect(pong['event'], 'pusher:pong');
    });

    test('parses tournament.updated event', () async {
      final transport = FakeWebSocketTransport();

      final client = ReverbTournamentRealtimeClient(
        host: 'localhost',
        port: 18081,
        appKey: 'test-key',
        useTls: false,
        transportFactory: (_) => transport,
      );

      addTearDown(client.dispose);

      await client.connect();

      final updateFuture = client.updates.first;

      transport.serverSend({
        'event': 'tournament.updated',
        'channel': 'tournament',
        'data': jsonEncode({
          'update_id': 'update-123',
          'occurred_at': '2026-08-10T20:00:00.000Z',
          'match': {
            'id': 1,
            'round_number': 1,
            'home_team_id': 1,
            'away_team_id': 2,
            'home_score': 2,
            'away_score': 1,
            'status': 'in_play',
            'kickoff_at': null,
          },
          'standings': [
            _standing(position: 1, teamId: 1, points: 3, goalDifference: 1),
            _standing(position: 2, teamId: 2, points: 0, goalDifference: -1),
          ],
        }),
      });

      final update = await updateFuture;

      expect(update.updateId, 'update-123');

      expect(update.game.homeScore, 2);

      expect(update.game.awayScore, 1);

      expect(update.game.status, GameStatus.inPlay);

      expect(update.standings.first.points, 3);
    });

    test('ignores tournament event from another channel', () async {
      final transport = FakeWebSocketTransport();

      final client = ReverbTournamentRealtimeClient(
        host: 'localhost',
        port: 18081,
        appKey: 'test-key',
        useTls: false,
        transportFactory: (_) => transport,
      );

      addTearDown(client.dispose);

      var receivedCount = 0;

      final subscription = client.updates.listen((_) => receivedCount++);

      addTearDown(subscription.cancel);

      await client.connect();

      transport.serverSend({
        'event': 'tournament.updated',
        'channel': 'something-else',
        'data': jsonEncode({'unexpected': true}),
      });

      await _flushEvents();

      expect(receivedCount, 0);
    });

    test('reconnects after the socket is closed', () async {
      final transports = <FakeWebSocketTransport>[];

      final client = ReverbTournamentRealtimeClient(
        host: 'localhost',
        port: 18081,
        appKey: 'test-key',
        useTls: false,
        reconnectDelay: (_) => Duration.zero,
        transportFactory: (_) {
          final transport = FakeWebSocketTransport();

          transports.add(transport);

          return transport;
        },
      );

      addTearDown(client.dispose);

      final statuses = <RealtimeConnectionStatus>[];

      final subscription = client.connectionStatuses.listen(statuses.add);

      addTearDown(subscription.cancel);

      await client.connect();

      expect(transports, hasLength(1));

      transports.first.serverSend({
        'event': 'pusher:connection_established',
        'data': '{}',
      });

      await _flushEvents();

      await transports.first.serverClose();

      await _flushEvents();
      await _flushEvents();

      expect(statuses, contains(RealtimeConnectionStatus.reconnecting));

      expect(transports.length, greaterThanOrEqualTo(2));
    });
  });
}

class FakeWebSocketTransport implements WebSocketTransport {
  final StreamController<dynamic> _incomingController =
      StreamController<dynamic>();

  final List<String> sentMessages = [];

  bool _closed = false;

  @override
  Future<void> get ready async {}

  @override
  Stream<dynamic> get messages {
    return _incomingController.stream;
  }

  @override
  void send(String message) {
    sentMessages.add(message);
  }

  void serverSend(Map<String, dynamic> message) {
    if (_closed) {
      return;
    }

    _incomingController.add(jsonEncode(message));
  }

  Future<void> serverClose() async {
    if (_closed) {
      return;
    }

    _closed = true;

    await _incomingController.close();
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;

    await _incomingController.close();
  }
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);

  await Future<void>.delayed(Duration.zero);
}

Map<String, dynamic> _standing({
  required int position,
  required int teamId,
  required int points,
  required int goalDifference,
}) {
  return {
    'position': position,
    'team_id': teamId,
    'played': 1,
    'won': points == 3 ? 1 : 0,
    'drawn': 0,
    'lost': points == 0 ? 1 : 0,
    'goals_for': goalDifference > 0 ? 2 : 1,
    'goals_against': goalDifference > 0 ? 1 : 2,
    'goal_difference': goalDifference,
    'points': points,
  };
}
