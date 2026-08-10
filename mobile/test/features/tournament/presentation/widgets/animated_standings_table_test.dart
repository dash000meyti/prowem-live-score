import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/features/tournament/domain/standing.dart';
import 'package:prowem_live_score/features/tournament/domain/team.dart';
import 'package:prowem_live_score/features/tournament/presentation/widgets/animated_standings_table.dart';

void main() {
  testWidgets('moves existing team rows when standings order changes', (
    tester,
  ) async {
    var standings = [
      _standing(position: 1, teamId: 1, points: 3),
      _standing(position: 2, teamId: 2, points: 1),
      _standing(position: 3, teamId: 3, points: 0),
      _standing(position: 4, teamId: 4, points: 0),
    ];

    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;

              return AnimatedStandingsTable(
                standings: standings,
                teamsById: _teams,
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final team1Finder = find.byKey(const ValueKey('standing-row-1'));

    final team2Finder = find.byKey(const ValueKey('standing-row-2'));

    expect(team1Finder, findsOneWidget);

    expect(team2Finder, findsOneWidget);

    final team1ElementBefore = tester.element(team1Finder);

    final team2ElementBefore = tester.element(team2Finder);

    final team1Initial = tester.getTopLeft(team1Finder);

    final team2Initial = tester.getTopLeft(team2Finder);

    expect(team1Initial.dy, lessThan(team2Initial.dy));

    rebuild(() {
      standings = [
        _standing(position: 1, teamId: 2, points: 4),
        _standing(position: 2, teamId: 1, points: 3),
        _standing(position: 3, teamId: 3, points: 0),
        _standing(position: 4, teamId: 4, points: 0),
      ];
    });

    await tester.pump();

    await tester.pump(const Duration(milliseconds: 225));

    final team1Mid = tester.getTopLeft(team1Finder);

    final team2Mid = tester.getTopLeft(team2Finder);

    expect(team1Mid.dy, greaterThan(team1Initial.dy));

    expect(team2Mid.dy, lessThan(team2Initial.dy));

    await tester.pumpAndSettle();

    final team1Final = tester.getTopLeft(team1Finder);

    final team2Final = tester.getTopLeft(team2Finder);

    expect(team2Final.dy, lessThan(team1Final.dy));

    expect(identical(team1ElementBefore, tester.element(team1Finder)), isTrue);

    expect(identical(team2ElementBefore, tester.element(team2Finder)), isTrue);
  });
}

final _teams = <int, Team>{
  1: const Team(id: 1, name: 'Juventus', logoUrl: null),
  2: const Team(id: 2, name: 'Inter', logoUrl: null),
  3: const Team(id: 3, name: 'AC Milan', logoUrl: null),
  4: const Team(id: 4, name: 'AS Roma', logoUrl: null),
};

Standing _standing({
  required int position,
  required int teamId,
  required int points,
}) {
  return Standing(
    position: position,
    teamId: teamId,
    played: points > 0 ? 1 : 0,
    won: points == 3 ? 1 : 0,
    drawn: points == 1 ? 1 : 0,
    lost: points == 0 ? 1 : 0,
    goalsFor: 0,
    goalsAgainst: 0,
    goalDifference: 0,
    points: points,
  );
}
