import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/app/app_theme.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';
import 'package:prowem_live_score/features/tournament/domain/team.dart';
import 'package:prowem_live_score/features/tournament/presentation/widgets/match_card.dart';

void main() {
  const juventus = Team(id: 1, name: 'Juventus', logoUrl: null);

  const inter = Team(id: 2, name: 'Inter', logoUrl: null);

  group('MatchCard', () {
    testWidgets('renders a scheduled match with zero scores', (tester) async {
      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(status: GameStatus.scheduled),
            homeTeam: juventus,
            awayTeam: inter,
            isBusy: false,
            isUpdating: false,
            onUpdateResult: _noopUpdate,
          ),
        ),
      );

      expect(find.text('NEXT MATCH'), findsOneWidget);

      expect(find.text('SCHEDULED'), findsOneWidget);

      expect(find.text('Juventus'), findsOneWidget);

      expect(find.text('Inter'), findsOneWidget);

      expect(find.text('0'), findsNWidgets(2));

      expect(find.text('Start match'), findsOneWidget);

      expect(find.text('+ GOAL'), findsNothing);
    });

    testWidgets('starting a scheduled match submits zero-zero as in_play', (
      tester,
    ) async {
      int? capturedGameId;
      int? capturedHomeScore;
      int? capturedAwayScore;
      GameStatus? capturedStatus;

      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(status: GameStatus.scheduled),
            homeTeam: juventus,
            awayTeam: inter,
            isBusy: false,
            isUpdating: false,
            onUpdateResult:
                ({
                  required int gameId,
                  required int homeScore,
                  required int awayScore,
                  required GameStatus status,
                }) async {
                  capturedGameId = gameId;
                  capturedHomeScore = homeScore;
                  capturedAwayScore = awayScore;
                  capturedStatus = status;
                },
          ),
        ),
      );

      await tester.tap(find.text('Start match'));

      await tester.pump();

      expect(capturedGameId, 1);

      expect(capturedHomeScore, 0);

      expect(capturedAwayScore, 0);

      expect(capturedStatus, GameStatus.inPlay);
    });

    testWidgets('renders live scoring controls for an in-play match', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(status: GameStatus.inPlay, homeScore: 1, awayScore: 0),
            homeTeam: juventus,
            awayTeam: inter,
            isBusy: false,
            isUpdating: false,
            onUpdateResult: _noopUpdate,
          ),
        ),
      );

      expect(find.text('LIVE MATCH'), findsOneWidget);

      expect(find.text('LIVE'), findsOneWidget);

      expect(find.text('+ GOAL'), findsNWidgets(2));

      expect(find.text('Edit / correct result'), findsOneWidget);

      expect(find.text('Start match'), findsNothing);
    });

    testWidgets('home goal button submits incremented home score', (
      tester,
    ) async {
      int? capturedGameId;
      int? capturedHomeScore;
      int? capturedAwayScore;
      GameStatus? capturedStatus;

      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(status: GameStatus.inPlay, homeScore: 1, awayScore: 2),
            homeTeam: juventus,
            awayTeam: inter,
            isBusy: false,
            isUpdating: false,
            onUpdateResult:
                ({
                  required int gameId,
                  required int homeScore,
                  required int awayScore,
                  required GameStatus status,
                }) async {
                  capturedGameId = gameId;
                  capturedHomeScore = homeScore;
                  capturedAwayScore = awayScore;
                  capturedStatus = status;
                },
          ),
        ),
      );

      final goalButtons = find.text('+ GOAL');

      expect(goalButtons, findsNWidgets(2));

      await tester.tap(goalButtons.first);

      await tester.pump();

      expect(capturedGameId, 1);

      expect(capturedHomeScore, 2);

      expect(capturedAwayScore, 2);

      expect(capturedStatus, GameStatus.inPlay);
    });

    testWidgets('away goal button submits incremented away score', (
      tester,
    ) async {
      int? capturedHomeScore;
      int? capturedAwayScore;
      GameStatus? capturedStatus;

      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(status: GameStatus.inPlay, homeScore: 2, awayScore: 1),
            homeTeam: juventus,
            awayTeam: inter,
            isBusy: false,
            isUpdating: false,
            onUpdateResult:
                ({
                  required int gameId,
                  required int homeScore,
                  required int awayScore,
                  required GameStatus status,
                }) async {
                  capturedHomeScore = homeScore;
                  capturedAwayScore = awayScore;
                  capturedStatus = status;
                },
          ),
        ),
      );

      final goalButtons = find.text('+ GOAL');

      await tester.tap(goalButtons.last);

      await tester.pump();

      expect(capturedHomeScore, 2);

      expect(capturedAwayScore, 2);

      expect(capturedStatus, GameStatus.inPlay);
    });

    testWidgets('opens correction action for an in-play match', (tester) async {
      var editCallCount = 0;

      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(status: GameStatus.inPlay, homeScore: 2, awayScore: 1),
            homeTeam: juventus,
            awayTeam: inter,
            isBusy: false,
            isUpdating: false,
            onUpdateResult: _noopUpdate,
            onEditResult: () {
              editCallCount++;
            },
          ),
        ),
      );

      await tester.tap(find.text('Edit / correct result'));

      await tester.pump();

      expect(editCallCount, 1);
    });

    testWidgets(
      'disables live scoring controls while another mutation is in progress',
      (tester) async {
        var updateCallCount = 0;

        await tester.pumpWidget(
          _testApp(
            MatchCard(
              game: _game(
                status: GameStatus.inPlay,
                homeScore: 1,
                awayScore: 0,
              ),
              homeTeam: juventus,
              awayTeam: inter,
              isBusy: true,
              isUpdating: false,
              onUpdateResult:
                  ({
                    required int gameId,
                    required int homeScore,
                    required int awayScore,
                    required GameStatus status,
                  }) async {
                    updateCallCount++;
                  },
            ),
          ),
        );

        final goalButtons = find.widgetWithText(FilledButton, '+ GOAL');

        expect(goalButtons, findsNWidgets(2));

        final firstGoalButton = tester.widget<FilledButton>(goalButtons.first);

        final secondGoalButton = tester.widget<FilledButton>(goalButtons.last);

        expect(firstGoalButton.onPressed, isNull);

        expect(secondGoalButton.onPressed, isNull);

        expect(updateCallCount, 0);
      },
    );

    testWidgets('disables start action while a mutation is in progress', (
      tester,
    ) async {
      var updateCallCount = 0;

      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(status: GameStatus.scheduled),
            homeTeam: juventus,
            awayTeam: inter,
            isBusy: true,
            isUpdating: false,
            onUpdateResult:
                ({
                  required int gameId,
                  required int homeScore,
                  required int awayScore,
                  required GameStatus status,
                }) async {
                  updateCallCount++;
                },
          ),
        ),
      );

      final startButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start match'),
      );

      expect(startButton.onPressed, isNull);

      expect(updateCallCount, 0);
    });

    testWidgets(
      'shows progress indicator for the match currently being updated',
      (tester) async {
        await tester.pumpWidget(
          _testApp(
            MatchCard(
              game: _game(
                status: GameStatus.inPlay,
                homeScore: 1,
                awayScore: 0,
              ),
              homeTeam: juventus,
              awayTeam: inter,
              isBusy: true,
              isUpdating: true,
              onUpdateResult: _noopUpdate,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('does not show progress indicator for another busy match', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(status: GameStatus.inPlay, homeScore: 1, awayScore: 0),
            homeTeam: juventus,
            awayTeam: inter,
            isBusy: true,
            isUpdating: false,
            onUpdateResult: _noopUpdate,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders final state without live scoring actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(
              status: GameStatus.finished,
              homeScore: 2,
              awayScore: 1,
            ),
            homeTeam: juventus,
            awayTeam: inter,
            isBusy: false,
            isUpdating: false,
            onUpdateResult: _noopUpdate,
          ),
        ),
      );

      expect(find.text('LATEST RESULT'), findsOneWidget);

      expect(find.text('FINAL'), findsOneWidget);

      expect(find.text('2'), findsOneWidget);

      expect(find.text('1'), findsOneWidget);

      expect(find.text('Correct result'), findsOneWidget);

      expect(find.text('+ GOAL'), findsNothing);

      expect(find.text('Start match'), findsNothing);
    });

    testWidgets('opens correction action for a finished match', (tester) async {
      var editCallCount = 0;

      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(
              status: GameStatus.finished,
              homeScore: 3,
              awayScore: 1,
            ),
            homeTeam: juventus,
            awayTeam: inter,
            isBusy: false,
            isUpdating: false,
            onUpdateResult: _noopUpdate,
            onEditResult: () {
              editCallCount++;
            },
          ),
        ),
      );

      await tester.tap(find.text('Correct result'));

      await tester.pump();

      expect(editCallCount, 1);
    });

    testWidgets('uses generic team fallback when team data is unavailable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          MatchCard(
            game: _game(status: GameStatus.scheduled),
            homeTeam: null,
            awayTeam: null,
            isBusy: false,
            isUpdating: false,
            onUpdateResult: _noopUpdate,
          ),
        ),
      );

      expect(find.text('Team'), findsNWidgets(2));

      expect(find.text('Start match'), findsOneWidget);
    });
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: Scaffold(
      body: Center(
        child: SingleChildScrollView(child: SizedBox(width: 400, child: child)),
      ),
    ),
  );
}

Game _game({required GameStatus status, int? homeScore, int? awayScore}) {
  return Game(
    id: 1,
    roundNumber: 1,
    homeTeamId: 1,
    awayTeamId: 2,
    homeScore: homeScore,
    awayScore: awayScore,
    status: status,
    kickoffAt: null,
  );
}

Future<void> _noopUpdate({
  required int gameId,
  required int homeScore,
  required int awayScore,
  required GameStatus status,
}) async {}
