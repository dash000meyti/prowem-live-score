abstract final class AppConfig {
  /// Laravel REST API.
  ///
  /// Android Emulator reaches the host machine through 10.0.2.2.
  ///
  /// Override for another platform with:
  ///
  /// --dart-define=API_BASE_URL=http://localhost:18080/api
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:18080/api',
  );

  /// Reverb WebSocket host.
  ///
  /// Do not use the Docker service name `reverb` here.
  /// That hostname is only resolvable inside Docker's network.
  static const String reverbHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: '10.0.2.2',
  );

  /// Host-side port published by docker-compose.
  static const int reverbPort = int.fromEnvironment(
    'REVERB_PORT',
    defaultValue: 18081,
  );

  /// Public Reverb application key.
  ///
  /// This is intentionally supplied at build/run time.
  /// Never expose REVERB_APP_SECRET to the Flutter application.
  static const String reverbAppKey = String.fromEnvironment('REVERB_APP_KEY');

  /// Local development uses ws://.
  ///
  /// Production should normally use TLS/wss://.
  static const bool reverbUseTls = bool.fromEnvironment(
    'REVERB_USE_TLS',
    defaultValue: false,
  );

  static Uri get apiUri {
    return Uri.parse(apiBaseUrl);
  }

  static Uri get reverbUri {
    return Uri(
      scheme: reverbUseTls ? 'wss' : 'ws',
      host: reverbHost,
      port: reverbPort,
    );
  }
}
