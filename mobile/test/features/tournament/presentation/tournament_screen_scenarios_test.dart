import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prowem_live_score/app/app_theme.dart';
import 'package:prowem_live_score/features/tournament/domain/game.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_providers.dart';
import 'package:prowem_live_score/features/tournament/presentation/tournament_screen.dart';
import 'package:prowem_live_score/features/tournament/presentation/widgets/match_card.dart';
import 'package:prowem_live_score/features/tournament/domain/tournament_snapshot.dart';

import '../../../support/tournament_scenario_support.dart';

void main() {
  group('TournamentScreen scenario regressions', () {
    testWidgets(
      'app start with two disjoint live matches exposes both quick-score cards',
      (tester) async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_twoLiveAndScheduledSnapshot()],
        );

        addTearDown(repository.dispose);

        await _pumpScenario(tester, repository);

        expect(find.byKey(const ValueKey('featured-match-1')), findsOneWidget);

        expect(find.byKey(const ValueKey('featured-match-2')), findsOneWidget);

        expect(find.text('LIVE MATCH'), findsNWidgets(2));
        expect(find.text('+ GOAL'), findsNWidgets(4));
      },
    );

    testWidgets(
      'score update in match B does not rebuild unrelated live match A card',
      (tester) async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_twoLiveAndScheduledSnapshot()],
        );

        addTearDown(repository.dispose);

        await _pumpScenario(tester, repository);

        final firstCardFinder = find.descendant(
          of: find.byKey(const ValueKey('featured-match-1')),
          matching: find.byType(MatchCard),
        );

        expect(firstCardFinder, findsOneWidget);

        final firstCardBefore = tester.widget<MatchCard>(firstCardFinder);

        repository.emitUpdate(
          scenarioUpdate(
            updateId: 'external-b',
            gameId: 2,
            round: 1,
            homeTeamId: 2,
            awayTeamId: 3,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus.inPlay,
            standings: standingsAfterInterWin(homeScore: 1, awayScore: 0),
          ),
        );

        await tester.pump();
        await tester.pump();

        final firstCardAfter = tester.widget<MatchCard>(firstCardFinder);

        expect(
          identical(firstCardBefore, firstCardAfter),
          isTrue,
          reason:
              'An unrelated live match card was rebuilt by another match score '
              'update.',
        );

        final secondMatch = find.byKey(const ValueKey('featured-match-2'));

        expect(
          find.descendant(of: secondMatch, matching: find.text('1')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'finalizing one of two live matches keeps the other live card visible',
      (tester) async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_twoLiveAndScheduledSnapshot()],
        );

        addTearDown(repository.dispose);

        await _pumpScenario(tester, repository);

        repository.emitUpdate(
          scenarioUpdate(
            updateId: 'finish-one',
            gameId: 1,
            round: 1,
            homeTeamId: 1,
            awayTeamId: 4,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus.finished,
            standings: standingsAfterJuventusWin(homeScore: 1, awayScore: 0),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('featured-match-1')), findsNothing);

        expect(find.byKey(const ValueKey('featured-match-2')), findsOneWidget);

        expect(find.text('LIVE MATCH'), findsOneWidget);
        expect(find.text('FINAL'), findsWidgets);
      },
    );

    testWidgets(
      'finalizing the last live match promotes the next scheduled match',
      (tester) async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_oneLiveOneScheduledSnapshot()],
        );

        addTearDown(repository.dispose);

        await _pumpScenario(tester, repository);

        expect(find.byKey(const ValueKey('featured-match-1')), findsOneWidget);

        repository.emitUpdate(
          scenarioUpdate(
            updateId: 'finish-last-live',
            gameId: 1,
            round: 1,
            homeTeamId: 1,
            awayTeamId: 4,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus.finished,
            standings: standingsAfterJuventusWin(homeScore: 1, awayScore: 0),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('featured-match-1')), findsNothing);

        expect(find.byKey(const ValueKey('featured-match-2')), findsOneWidget);

        expect(find.text('NEXT MATCH'), findsOneWidget);
        expect(find.text('Start match'), findsOneWidget);
      },
    );

    testWidgets(
      'when tournament has no scheduled matches the latest finished result remains focused',
      (tester) async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_singleLiveSnapshot()],
        );

        addTearDown(repository.dispose);

        await _pumpScenario(tester, repository);

        repository.emitUpdate(
          scenarioUpdate(
            updateId: 'finish-tournament',
            gameId: 1,
            round: 1,
            homeTeamId: 1,
            awayTeamId: 4,
            homeScore: 2,
            awayScore: 1,
            status: GameStatus.finished,
            standings: standingsAfterJuventusWin(homeScore: 2, awayScore: 1),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('featured-match-1')), findsOneWidget);

        expect(find.text('LATEST RESULT'), findsOneWidget);
        expect(find.text('FINAL'), findsWidgets);
      },
    );

    testWidgets(
      'starting a scheduled match at zero-zero renders a real live zero-zero match',
      (tester) async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_singleScheduledSnapshot()],
        );

        repository.responseFactory = (call) {
          return scenarioUpdate(
            updateId: 'start-zero-zero',
            gameId: 1,
            round: 1,
            homeTeamId: 1,
            awayTeamId: 4,
            homeScore: call.homeScore,
            awayScore: call.awayScore,
            status: call.status,
            standings: [
              standingJson(
                position: 1,
                teamId: 1,
                played: 1,
                drawn: 1,
                goalsFor: 0,
                goalsAgainst: 0,
                points: 1,
              ),
              standingJson(
                position: 2,
                teamId: 4,
                played: 1,
                drawn: 1,
                goalsFor: 0,
                goalsAgainst: 0,
                points: 1,
              ),
              standingJson(position: 3, teamId: 2),
              standingJson(position: 4, teamId: 3),
            ],
          );
        };

        addTearDown(repository.dispose);

        await _pumpScenario(tester, repository);

        await tester.tap(find.widgetWithText(FilledButton, 'Start match'));

        await tester.pump();
        await tester.pumpAndSettle();

        final featured = find.byKey(const ValueKey('featured-match-1'));

        expect(
          find.descendant(of: featured, matching: find.text('LIVE MATCH')),
          findsOneWidget,
        );

        expect(
          find.descendant(of: featured, matching: find.text('0')),
          findsNWidgets(2),
        );

        expect(repository.mutationCalls, hasLength(1));
        expect(repository.mutationCalls.single.homeScore, 0);
        expect(repository.mutationCalls.single.awayScore, 0);
        expect(repository.mutationCalls.single.status, GameStatus.inPlay);
      },
    );

    testWidgets(
      'scroll position is preserved by an external score-only realtime update',
      (tester) async {
        final repository = ScenarioTournamentRepository(
          snapshots: [_twoLiveAndScheduledSnapshot()],
        );

        addTearDown(repository.dispose);

        tester.view.physicalSize = const Size(800, 700);
        tester.view.devicePixelRatio = 1;

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpScenario(tester, repository);

        await tester.drag(find.byType(ListView), const Offset(0, -350));
        await tester.pumpAndSettle();

        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );

        final before = scrollable.position.pixels;

        repository.emitUpdate(
          scenarioUpdate(
            updateId: 'scroll-update',
            gameId: 2,
            round: 1,
            homeTeamId: 2,
            awayTeamId: 3,
            homeScore: 2,
            awayScore: 0,
            status: GameStatus.inPlay,
            standings: standingsAfterInterWin(homeScore: 2, awayScore: 0),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));

        final after = scrollable.position.pixels;

        expect(
          after,
          closeTo(before, 1),
          reason:
              'A score-only realtime update should not jump the operator back '
              'to another scroll position.',
        );
      },
    );
  });
}

Future<void> _pumpScenario(
  WidgetTester tester,
  ScenarioTournamentRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [tournamentRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(theme: AppTheme.dark, home: const TournamentScreen()),
    ),
  );

  await tester.pump();
  await tester.pumpAndSettle();
}

TournamentSnapshot _twoLiveAndScheduledSnapshot() {
  return scenarioSnapshot(
    matches: [
      matchJson(
        id: 1,
        round: 1,
        homeTeamId: 1,
        awayTeamId: 4,
        homeScore: 0,
        awayScore: 0,
        status: GameStatus.inPlay,
      ),
      matchJson(
        id: 2,
        round: 1,
        homeTeamId: 2,
        awayTeamId: 3,
        homeScore: 0,
        awayScore: 0,
        status: GameStatus.inPlay,
      ),
      matchJson(
        id: 3,
        round: 2,
        homeTeamId: 1,
        awayTeamId: 2,
        status: GameStatus.scheduled,
      ),
    ],
    standings: neutralStandings(),
  );
}

TournamentSnapshot _oneLiveOneScheduledSnapshot() {
  return scenarioSnapshot(
    matches: [
      matchJson(
        id: 1,
        round: 1,
        homeTeamId: 1,
        awayTeamId: 4,
        homeScore: 1,
        awayScore: 0,
        status: GameStatus.inPlay,
      ),
      matchJson(
        id: 2,
        round: 2,
        homeTeamId: 2,
        awayTeamId: 3,
        status: GameStatus.scheduled,
      ),
    ],
    standings: standingsAfterJuventusWin(homeScore: 1, awayScore: 0),
  );
}

TournamentSnapshot _singleLiveSnapshot() {
  return scenarioSnapshot(
    matches: [
      matchJson(
        id: 1,
        round: 1,
        homeTeamId: 1,
        awayTeamId: 4,
        homeScore: 2,
        awayScore: 1,
        status: GameStatus.inPlay,
      ),
    ],
    standings: standingsAfterJuventusWin(homeScore: 2, awayScore: 1),
  );
}

TournamentSnapshot _singleScheduledSnapshot() {
  return scenarioSnapshot(
    matches: [
      matchJson(
        id: 1,
        round: 1,
        homeTeamId: 1,
        awayTeamId: 4,
        status: GameStatus.scheduled,
      ),
    ],
    standings: neutralStandings(),
  );
}
