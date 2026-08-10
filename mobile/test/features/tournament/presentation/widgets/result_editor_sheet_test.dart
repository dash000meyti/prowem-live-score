import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/app/app_theme.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';
import 'package:prowem_live_score/features/tournament/domain/team.dart';
import 'package:prowem_live_score/features/tournament/presentation/widgets/result_editor_sheet.dart';

void main() {
  const homeTeam = Team(id: 1, name: 'AC Milan', logoUrl: null);

  const awayTeam = Team(id: 2, name: 'Juventus', logoUrl: null);

  testWidgets(
    'scheduled match cannot start when one of its teams is already live',
    (tester) async {
      await tester.pumpWidget(
        _testApp(
          ResultEditorSheet(
            game: _scheduledGame(),
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            startBlocked: true,
          ),
        ),
      );

      expect(
        find.textContaining('already playing another live match'),
        findsOneWidget,
      );

      final startButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start match'),
      );

      expect(startButton.onPressed, isNull);
    },
  );

  testWidgets('scheduled match can start when neither team is already live', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        ResultEditorSheet(
          game: _scheduledGame(),
          homeTeam: homeTeam,
          awayTeam: awayTeam,
        ),
      ),
    );

    final startButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Start match'),
    );

    expect(startButton.onPressed, isNotNull);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

Game _scheduledGame() {
  return const Game(
    id: 3,
    roundNumber: 2,
    homeTeamId: 1,
    awayTeamId: 2,
    homeScore: null,
    awayScore: null,
    status: GameStatus.scheduled,
    kickoffAt: null,
  );
}
