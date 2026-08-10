import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../data/reverb_tournament_realtime_client.dart';
import '../data/tournament_api.dart';
import '../data/tournament_realtime_client.dart';
import '../data/tournament_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final tournamentRealtimeClientProvider = Provider<TournamentRealtimeClient>((
  ref,
) {
  final client = ReverbTournamentRealtimeClient(
    host: AppConfig.reverbHost,
    port: AppConfig.reverbPort,
    appKey: AppConfig.reverbAppKey,
    useTls: AppConfig.reverbUseTls,
  );

  ref.onDispose(() {
    unawaited(client.dispose());
  });

  return client;
});

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return DefaultTournamentRepository(
    api: TournamentApi(ref.watch(apiClientProvider).dio),
    realtimeClient: ref.watch(tournamentRealtimeClientProvider),
  );
});
