<?php

namespace Tests\Unit;

use App\Enums\GameStatus;
use App\Models\Game;
use App\Models\Team;
use App\Services\Tournament\StandingsCalculator;
use Illuminate\Support\Collection;
use LogicException;
use PHPUnit\Framework\TestCase;

class StandingsCalculatorTest extends TestCase
{
    private StandingsCalculator $calculator;

    protected function setUp(): void
    {
        parent::setUp();

        $this->calculator = new StandingsCalculator();
    }

    public function test_all_teams_start_with_zero_stats(): void
    {
        $standings = $this->calculator->calculate(
            $this->teams(),
            collect()
        );

        $this->assertSame([1, 2, 3, 4], $standings->pluck('team_id')->all());

        foreach ($standings as $standing) {
            $this->assertSame(0, $standing['played']);
            $this->assertSame(0, $standing['won']);
            $this->assertSame(0, $standing['drawn']);
            $this->assertSame(0, $standing['lost']);
            $this->assertSame(0, $standing['goals_for']);
            $this->assertSame(0, $standing['goals_against']);
            $this->assertSame(0, $standing['goal_difference']);
            $this->assertSame(0, $standing['points']);
        }
    }

    public function test_scheduled_matches_do_not_count_towards_standings(): void
    {
        $games = collect([
            $this->game(
                homeTeamId: 1,
                awayTeamId: 2,
                homeScore: null,
                awayScore: null,
                status: GameStatus::Scheduled
            ),
        ]);

        $standings = $this->calculator->calculate(
            $this->teams(),
            $games
        );

        $this->assertSame(0, $standings->sum('played'));
        $this->assertSame(0, $standings->sum('points'));
    }

    public function test_home_win_is_calculated_correctly(): void
    {
        $standings = $this->calculator->calculate(
            $this->teams(2),
            collect([
                $this->game(1, 2, 2, 1, GameStatus::Finished),
            ])
        )->keyBy('team_id');

        $home = $standings[1];
        $away = $standings[2];

        $this->assertSame(1, $home['played']);
        $this->assertSame(1, $home['won']);
        $this->assertSame(0, $home['drawn']);
        $this->assertSame(0, $home['lost']);
        $this->assertSame(2, $home['goals_for']);
        $this->assertSame(1, $home['goals_against']);
        $this->assertSame(1, $home['goal_difference']);
        $this->assertSame(3, $home['points']);

        $this->assertSame(1, $away['played']);
        $this->assertSame(0, $away['won']);
        $this->assertSame(0, $away['drawn']);
        $this->assertSame(1, $away['lost']);
        $this->assertSame(1, $away['goals_for']);
        $this->assertSame(2, $away['goals_against']);
        $this->assertSame(-1, $away['goal_difference']);
        $this->assertSame(0, $away['points']);
    }

    public function test_away_win_is_calculated_correctly(): void
    {
        $standings = $this->calculator->calculate(
            $this->teams(2),
            collect([
                $this->game(1, 2, 0, 2, GameStatus::Finished),
            ])
        )->keyBy('team_id');

        $this->assertSame(0, $standings[1]['points']);
        $this->assertSame(1, $standings[1]['lost']);

        $this->assertSame(3, $standings[2]['points']);
        $this->assertSame(1, $standings[2]['won']);
    }

    public function test_draw_is_calculated_correctly(): void
    {
        $standings = $this->calculator->calculate(
            $this->teams(2),
            collect([
                $this->game(1, 2, 1, 1, GameStatus::Finished),
            ])
        )->keyBy('team_id');

        foreach ([1, 2] as $teamId) {
            $this->assertSame(1, $standings[$teamId]['played']);
            $this->assertSame(0, $standings[$teamId]['won']);
            $this->assertSame(1, $standings[$teamId]['drawn']);
            $this->assertSame(0, $standings[$teamId]['lost']);
            $this->assertSame(1, $standings[$teamId]['points']);
        }
    }

    public function test_in_play_match_counts_immediately(): void
    {
        $standings = $this->calculator->calculate(
            $this->teams(2),
            collect([
                $this->game(1, 2, 1, 0, GameStatus::InPlay),
            ])
        )->keyBy('team_id');

        $this->assertSame(3, $standings[1]['points']);
        $this->assertSame(0, $standings[2]['points']);
    }

    public function test_ranking_prioritizes_points(): void
    {
        $standings = $this->calculator->calculate(
            $this->teams(),
            collect([
                $this->game(1, 2, 1, 0, GameStatus::Finished),
            ])
        );

        $this->assertSame(1, $standings[0]['team_id']);
        $this->assertSame(3, $standings[0]['points']);
    }

    public function test_goal_difference_breaks_a_points_tie(): void
    {
        $standings = $this->calculator->calculate(
            $this->teams(),
            collect([
                $this->game(1, 3, 2, 0, GameStatus::Finished),
                $this->game(2, 4, 1, 0, GameStatus::Finished),
            ])
        );

        $this->assertSame(1, $standings[0]['team_id']);
        $this->assertSame(2, $standings[0]['goal_difference']);

        $this->assertSame(2, $standings[1]['team_id']);
        $this->assertSame(1, $standings[1]['goal_difference']);
    }

    public function test_goals_for_breaks_a_points_and_goal_difference_tie(): void
    {
        $standings = $this->calculator->calculate(
            $this->teams(),
            collect([
                $this->game(1, 3, 2, 1, GameStatus::Finished),
                $this->game(2, 4, 1, 0, GameStatus::Finished),
            ])
        );

        $this->assertSame(1, $standings[0]['team_id']);
        $this->assertSame(2, $standings[0]['goals_for']);

        $this->assertSame(2, $standings[1]['team_id']);
        $this->assertSame(1, $standings[1]['goals_for']);
    }

    public function test_team_id_provides_a_deterministic_final_tiebreaker(): void
    {
        $standings = $this->calculator->calculate(
            $this->teams(),
            collect()
        );

        $this->assertSame(
            [1, 2, 3, 4],
            $standings->pluck('team_id')->all()
        );
    }

    public function test_a_live_goal_can_change_the_ranking(): void
    {
        $teams = $this->teams();

        $baseGames = collect([
            // Juventus 1-0 Roma
            $this->game(1, 4, 1, 0, GameStatus::Finished),

            // Juventus 0-0 Inter
            $this->game(1, 2, 0, 0, GameStatus::Finished),

            // AC Milan 1-0 Roma
            $this->game(3, 4, 1, 0, GameStatus::Finished),

            // Inter 3-0 Roma
            $this->game(2, 4, 3, 0, GameStatus::Finished),

            // AC Milan 0-0 Inter, currently live
            $this->game(3, 2, 0, 0, GameStatus::InPlay),

            // Juventus vs AC Milan has not started
            $this->game(1, 3, null, null, GameStatus::Scheduled),
        ]);

        $beforeGoal = $this->calculator->calculate(
            $teams,
            $baseGames
        );

        $this->assertSame(
            [2, 1, 3, 4],
            $beforeGoal->pluck('team_id')->all()
        );

        $liveMatch = $baseGames[4];

        $liveMatch->home_score = 1;

        $afterGoal = $this->calculator->calculate(
            $teams,
            $baseGames
        );

        $this->assertSame(
            [3, 2, 1, 4],
            $afterGoal->pluck('team_id')->all()
        );

        $this->assertSame(1, $afterGoal[0]['position']);
        $this->assertSame(3, $afterGoal[0]['team_id']);
        $this->assertSame(6, $afterGoal[0]['points']);
    }

    public function test_it_rejects_an_in_play_match_without_a_score(): void
    {
        $this->expectException(LogicException::class);

        $this->calculator->calculate(
            $this->teams(2),
            collect([
                $this->game(
                    1,
                    2,
                    null,
                    null,
                    GameStatus::InPlay
                ),
            ])
        );
    }

    public function test_it_rejects_a_finished_match_without_a_score(): void
    {
        $this->expectException(LogicException::class);

        $this->calculator->calculate(
            $this->teams(2),
            collect([
                $this->game(
                    1,
                    2,
                    null,
                    null,
                    GameStatus::Finished
                ),
            ])
        );
    }

    public function test_it_rejects_a_match_with_an_unknown_team(): void
    {
        $this->expectException(LogicException::class);

        $this->calculator->calculate(
            $this->teams(2),
            collect([
                $this->game(
                    1,
                    999,
                    1,
                    0,
                    GameStatus::Finished
                ),
            ])
        );
    }

    public function test_it_rejects_a_team_playing_itself(): void
    {
        $this->expectException(LogicException::class);

        $this->calculator->calculate(
            $this->teams(2),
            collect([
                $this->game(
                    1,
                    1,
                    1,
                    0,
                    GameStatus::Finished
                ),
            ])
        );
    }

    private function teams(int $count = 4): Collection
    {
        $names = [
            1 => 'Juventus',
            2 => 'Inter',
            3 => 'AC Milan',
            4 => 'AS Roma',
        ];

        return collect(range(1, $count))
            ->map(function (int $id) use ($names): Team {
                $team = new Team([
                    'name' => $names[$id] ?? "Team {$id}",
                ]);

                $team->id = $id;

                return $team;
            });
    }

    private function game(
        int $homeTeamId,
        int $awayTeamId,
        ?int $homeScore,
        ?int $awayScore,
        GameStatus $status
    ): Game {
        return new Game([
            'home_team_id' => $homeTeamId,
            'away_team_id' => $awayTeamId,
            'home_score' => $homeScore,
            'away_score' => $awayScore,
            'status' => $status,
        ]);
    }
}
