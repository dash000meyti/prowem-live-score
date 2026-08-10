import 'package:web_socket_channel/web_socket_channel.dart';

abstract interface class WebSocketTransport {
  Future<void> get ready;

  Stream<dynamic> get messages;

  void send(String message);

  Future<void> close();
}

typedef WebSocketTransportFactory = WebSocketTransport Function(Uri uri);

class WebSocketChannelTransport implements WebSocketTransport {
  WebSocketChannelTransport._(this._channel);

  factory WebSocketChannelTransport.connect(Uri uri) {
    return WebSocketChannelTransport._(WebSocketChannel.connect(uri));
  }

  final WebSocketChannel _channel;

  @override
  Future<void> get ready => _channel.ready;

  @override
  Stream<dynamic> get messages => _channel.stream;

  @override
  void send(String message) {
    _channel.sink.add(message);
  }

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}
