class Standing {
  const Standing({
    required this.position,
    required this.teamId,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  final int position;
  final int teamId;

  final int played;
  final int won;
  final int drawn;
  final int lost;

  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;

  final int points;

  factory Standing.fromJson(Map<String, dynamic> json) {
    return Standing(
      position: json['position'] as int,
      teamId: json['team_id'] as int,
      played: json['played'] as int,
      won: json['won'] as int,
      drawn: json['drawn'] as int,
      lost: json['lost'] as int,
      goalsFor: json['goals_for'] as int,
      goalsAgainst: json['goals_against'] as int,
      goalDifference: json['goal_difference'] as int,
      points: json['points'] as int,
    );
  }
}
