enum GameStatus {
  scheduled,
  inPlay,
  finished;

  factory GameStatus.fromApi(String value) {
    return switch (value) {
      'scheduled' => GameStatus.scheduled,
      'in_play' => GameStatus.inPlay,
      'finished' => GameStatus.finished,
      _ => throw FormatException('Unknown game status: $value'),
    };
  }

  String get apiValue {
    return switch (this) {
      GameStatus.scheduled => 'scheduled',
      GameStatus.inPlay => 'in_play',
      GameStatus.finished => 'finished',
    };
  }
}

class Game {
  const Game({
    required this.id,
    required this.roundNumber,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.kickoffAt,
  });

  final int id;
  final int roundNumber;

  final int homeTeamId;
  final int awayTeamId;

  final int? homeScore;
  final int? awayScore;

  final GameStatus status;

  final DateTime? kickoffAt;

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as int,
      roundNumber: json['round_number'] as int,
      homeTeamId: json['home_team_id'] as int,
      awayTeamId: json['away_team_id'] as int,
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      status: GameStatus.fromApi(json['status'] as String),
      kickoffAt: json['kickoff_at'] == null
          ? null
          : DateTime.parse(json['kickoff_at'] as String),
    );
  }
}
