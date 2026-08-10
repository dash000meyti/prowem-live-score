<?php

namespace Tests\Feature;

use App\Enums\GameStatus;
use App\Models\Game;
use Database\Seeders\TournamentSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TournamentReadApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(TournamentSeeder::class);
    }

    public function test_tournament_snapshot_contains_teams_matches_and_standings(): void
    {
        $response = $this->getJson(
            route('tournament.show')
        );

        $response
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'teams' => [
                        '*' => [
                            'id',
                            'name',
                            'logo_url',
                        ],
                    ],

                    'matches' => [
                        '*' => [
                            'id',
                            'round_number',
                            'home_team_id',
                            'away_team_id',
                            'home_team',
                            'away_team',
                            'home_score',
                            'away_score',
                            'status',
                            'kickoff_at',
                        ],
                    ],

                    'standings' => [
                        '*' => [
                            'position',
                            'team_id',
                            'played',
                            'won',
                            'drawn',
                            'lost',
                            'goals_for',
                            'goals_against',
                            'goal_difference',
                            'points',
                        ],
                    ],
                ],
            ])
            ->assertJsonCount(4, 'data.teams')
            ->assertJsonCount(6, 'data.matches')
            ->assertJsonCount(4, 'data.standings');
    }

    public function test_matches_are_returned_in_round_order(): void
    {
        $response = $this->getJson(
            route('matches.index')
        );

        $response
            ->assertOk()
            ->assertJsonCount(6, 'data');

        $roundNumbers = collect(
            $response->json('data')
        )->pluck('round_number')->all();

        $this->assertSame(
            [1, 1, 2, 2, 3, 3],
            $roundNumbers
        );
    }

    public function test_initial_standings_are_zeroed_and_deterministic(): void
    {
        $response = $this->getJson(
            route('standings.index')
        );

        $response
            ->assertOk()
            ->assertJsonCount(4, 'data');

        foreach ($response->json('data') as $standing) {
            $this->assertSame(0, $standing['played']);
            $this->assertSame(0, $standing['points']);
            $this->assertSame(0, $standing['goal_difference']);
        }

        $this->assertSame(
            [1, 2, 3, 4],
            collect($response->json('data'))
                ->pluck('position')
                ->all()
        );
    }

    public function test_standings_reflect_current_match_results(): void
    {
        $game = Game::query()->firstOrFail();

        $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => 2,
                'away_score' => 0,
                'status' => GameStatus::InPlay->value,
            ]
        )->assertOk();

        $response = $this->getJson(
            route('standings.index')
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.0.team_id',
                $game->home_team_id
            )
            ->assertJsonPath(
                'data.0.points',
                3
            )
            ->assertJsonPath(
                'data.0.goal_difference',
                2
            );
    }

    public function test_tournament_snapshot_reflects_the_latest_match_state(): void
    {
        $game = Game::query()->firstOrFail();

        $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => 1,
                'away_score' => 1,
                'status' => GameStatus::InPlay->value,
            ]
        )->assertOk();

        $response = $this->getJson(
            route('tournament.show')
        );

        $response->assertOk();

        $match = collect(
            $response->json('data.matches')
        )->firstWhere('id', $game->id);

        $this->assertNotNull($match);

        $this->assertSame(
            1,
            $match['home_score']
        );

        $this->assertSame(
            1,
            $match['away_score']
        );

        $this->assertSame(
            GameStatus::InPlay->value,
            $match['status']
        );
    }
}
