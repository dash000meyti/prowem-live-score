import 'game.dart';
import 'standing.dart';
import 'team.dart';

class TournamentSnapshot {
  const TournamentSnapshot({
    required this.teams,
    required this.games,
    required this.standings,
  });

  final List<Team> teams;
  final List<Game> games;
  final List<Standing> standings;

  factory TournamentSnapshot.fromJson(Map<String, dynamic> json) {
    return TournamentSnapshot(
      teams: (json['teams'] as List<dynamic>)
          .map((item) => Team.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),

      games: (json['matches'] as List<dynamic>)
          .map((item) => Game.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),

      standings: (json['standings'] as List<dynamic>)
          .map((item) => Standing.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  TournamentSnapshot applyUpdate(TournamentUpdate update) {
    final updatedGames = games
        .map((game) => game.id == update.game.id ? update.game : game)
        .toList(growable: false);

    return TournamentSnapshot(
      teams: teams,
      games: updatedGames,
      standings: update.standings,
    );
  }
}

class TournamentUpdate {
  const TournamentUpdate({
    required this.updateId,
    required this.occurredAt,
    required this.game,
    required this.standings,
  });

  final String updateId;
  final DateTime occurredAt;
  final Game game;
  final List<Standing> standings;

  factory TournamentUpdate.fromJson(Map<String, dynamic> json) {
    return TournamentUpdate(
      updateId: json['update_id'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      game: Game.fromJson(json['match'] as Map<String, dynamic>),
      standings: (json['standings'] as List<dynamic>)
          .map((item) => Standing.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
