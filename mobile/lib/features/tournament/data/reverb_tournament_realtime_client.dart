import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../../core/network/web_socket_transport.dart';
import '../domain/tournament_snapshot.dart';
import 'tournament_realtime_client.dart';

class ReverbTournamentRealtimeClient implements TournamentRealtimeClient {
  ReverbTournamentRealtimeClient({
    required String host,
    required int port,
    required String appKey,
    required bool useTls,
    WebSocketTransportFactory? transportFactory,
    Duration Function(int attempt)? reconnectDelay,
    Duration handshakeTimeout = const Duration(seconds: 5),
  }) : _host = host,
       _port = port,
       _appKey = appKey,
       // Public constructor API intentionally uses `useTls`
       // while the implementation keeps the field private.
       // ignore: prefer_initializing_formals
       _useTls = useTls,
       _transportFactory =
           transportFactory ?? WebSocketChannelTransport.connect,
       _reconnectDelay = reconnectDelay ?? _defaultReconnectDelay,
       // Public constructor API intentionally uses `handshakeTimeout`
       // while the implementation keeps the field private.
       // ignore: prefer_initializing_formals
       _handshakeTimeout = handshakeTimeout {
    if (host.trim().isEmpty) {
      throw ArgumentError.value(host, 'host', 'Reverb host must not be empty.');
    }

    if (port <= 0 || port > 65535) {
      throw ArgumentError.value(
        port,
        'port',
        'Reverb port must be between 1 and 65535.',
      );
    }

    if (appKey.trim().isEmpty) {
      throw ArgumentError.value(
        appKey,
        'appKey',
        'Reverb app key must not be empty.',
      );
    }
  }

  static const _channelName = 'tournament';
  static const _eventName = 'tournament.updated';

  final String _host;
  final int _port;
  final String _appKey;
  final bool _useTls;

  final WebSocketTransportFactory _transportFactory;
  final Duration Function(int attempt) _reconnectDelay;
  final Duration _handshakeTimeout;

  final StreamController<TournamentUpdate> _updatesController =
      StreamController<TournamentUpdate>.broadcast();

  final StreamController<RealtimeConnectionStatus> _statusController =
      StreamController<RealtimeConnectionStatus>.broadcast();

  WebSocketTransport? _transport;
  StreamSubscription<dynamic>? _socketSubscription;

  Timer? _reconnectTimer;
  Timer? _handshakeTimer;

  RealtimeConnectionStatus? _lastStatus;

  bool _disposed = false;
  bool _connecting = false;

  int _generation = 0;
  int _reconnectAttempt = 0;

  @override
  Stream<TournamentUpdate> get updates {
    return _updatesController.stream;
  }

  @override
  Stream<RealtimeConnectionStatus> get connectionStatuses {
    return _statusController.stream;
  }

  Uri get _uri {
    return Uri(
      scheme: _useTls ? 'wss' : 'ws',
      host: _host,
      port: _port,
      pathSegments: ['app', _appKey],
      queryParameters: const {
        'protocol': '7',
        'client': 'flutter',
        'version': '1.0',
        'flash': 'false',
      },
    );
  }

  @override
  Future<void> connect() async {
    if (_disposed) {
      throw StateError('Cannot connect a disposed realtime client.');
    }

    if (_connecting || _transport != null) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _connecting = true;

    final generation = ++_generation;

    _emitStatus(
      _reconnectAttempt == 0
          ? RealtimeConnectionStatus.connecting
          : RealtimeConnectionStatus.reconnecting,
    );

    try {
      final transport = _transportFactory(_uri);

      _transport = transport;

      _socketSubscription = transport.messages.listen(
        (message) {
          _handleRawMessage(message, generation);
        },
        onError: (Object error, StackTrace stackTrace) {
          _handleDisconnect(generation);
        },
        onDone: () {
          _handleDisconnect(generation);
        },
        cancelOnError: false,
      );

      await transport.ready;

      if (_disposed || generation != _generation) {
        await transport.close();
        return;
      }

      // Usually Reverb sends pusher:connection_established
      // immediately. This protects us from a socket that
      // opens but never completes the Pusher handshake.
      if (_lastStatus != RealtimeConnectionStatus.connected) {
        _handshakeTimer?.cancel();

        _handshakeTimer = Timer(_handshakeTimeout, () {
          _handleDisconnect(generation);
        });
      }
    } catch (_) {
      _handleDisconnect(generation);
    } finally {
      if (generation == _generation) {
        _connecting = false;
      }
    }
  }

  void _handleRawMessage(dynamic rawMessage, int generation) {
    if (_disposed || generation != _generation || rawMessage is! String) {
      return;
    }

    try {
      final envelope = _decodeObject(rawMessage);

      if (envelope == null) {
        return;
      }

      final event = envelope['event'];

      if (event is! String) {
        return;
      }

      switch (event) {
        case 'pusher:connection_established':
          _handleConnectionEstablished();
          return;

        case 'pusher:ping':
          _send({'event': 'pusher:pong', 'data': const {}});
          return;

        case 'pusher:error':
          _handleDisconnect(generation);
          return;
      }

      if (event.startsWith('pusher:') || event.startsWith('pusher_internal:')) {
        return;
      }

      if (event != _eventName) {
        return;
      }

      if (envelope['channel'] != _channelName) {
        return;
      }

      final data = _decodeObject(envelope['data']);

      if (data == null) {
        throw const FormatException(
          'Realtime tournament event has invalid data.',
        );
      }

      final update = TournamentUpdate.fromJson(data);

      if (!_updatesController.isClosed) {
        _updatesController.add(update);
      }
    } catch (error, stackTrace) {
      if (!_updatesController.isClosed) {
        _updatesController.addError(error, stackTrace);
      }
    }
  }

  void _handleConnectionEstablished() {
    _handshakeTimer?.cancel();
    _handshakeTimer = null;

    _reconnectAttempt = 0;

    _subscribeToTournament();

    _emitStatus(RealtimeConnectionStatus.connected);
  }

  void _subscribeToTournament() {
    _send({
      'event': 'pusher:subscribe',
      'data': const {'channel': _channelName},
    });
  }

  void _send(Map<String, dynamic> payload) {
    final transport = _transport;

    if (transport == null) {
      return;
    }

    transport.send(jsonEncode(payload));
  }

  void _handleDisconnect(int generation) {
    if (_disposed || generation != _generation) {
      return;
    }

    // Invalidate callbacks belonging to the disconnected socket.
    _generation++;

    _connecting = false;

    _handshakeTimer?.cancel();
    _handshakeTimer = null;

    final subscription = _socketSubscription;
    _socketSubscription = null;

    if (subscription != null) {
      unawaited(subscription.cancel());
    }

    final transport = _transport;
    _transport = null;

    if (transport != null) {
      unawaited(transport.close());
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectTimer != null) {
      return;
    }

    _reconnectAttempt++;

    _emitStatus(RealtimeConnectionStatus.reconnecting);

    final delay = _reconnectDelay(_reconnectAttempt);

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;

      if (!_disposed) {
        unawaited(connect());
      }
    });
  }

  void _emitStatus(RealtimeConnectionStatus status) {
    if (_lastStatus == status || _statusController.isClosed) {
      return;
    }

    _lastStatus = status;

    _statusController.add(status);
  }

  static Duration _defaultReconnectDelay(int attempt) {
    // 1s → 2s → 4s → 8s → 8s...
    final exponent = min(max(attempt - 1, 0), 3);

    return Duration(seconds: 1 << exponent);
  }

  Map<String, dynamic>? _decodeObject(dynamic value) {
    dynamic decoded = value;

    if (value is String) {
      decoded = jsonDecode(value);
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return null;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    ++_generation;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _handshakeTimer?.cancel();
    _handshakeTimer = null;

    final subscription = _socketSubscription;
    _socketSubscription = null;

    if (subscription != null) {
      await subscription.cancel();
    }

    final transport = _transport;
    _transport = null;

    if (transport != null) {
      await transport.close();
    }

    _emitStatus(RealtimeConnectionStatus.disconnected);

    await _updatesController.close();
    await _statusController.close();
  }
}
