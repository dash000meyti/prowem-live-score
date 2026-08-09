<?php

namespace Tests\Feature;

use App\Enums\GameStatus;
use App\Models\Game;
use App\Models\Team;
use Database\Seeders\TournamentSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class UpdateMatchResultTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(TournamentSeeder::class);
    }

    public function test_a_scheduled_match_can_be_started(): void
    {
        $game = Game::query()->firstOrFail();

        $response = $this->updateGame(
            $game,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus::InPlay
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.match.id', $game->id)
            ->assertJsonPath('data.match.home_score', 1)
            ->assertJsonPath('data.match.away_score', 0)
            ->assertJsonPath(
                'data.match.status',
                GameStatus::InPlay->value
            );

        $this->assertDatabaseHas('matches', [
            'id' => $game->id,
            'home_score' => 1,
            'away_score' => 0,
            'status' => GameStatus::InPlay->value,
        ]);
    }

    public function test_a_scheduled_match_can_be_finished_directly(): void
    {
        $game = Game::query()->firstOrFail();

        $response = $this->updateGame(
            $game,
            homeScore: 3,
            awayScore: 2,
            status: GameStatus::Finished
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.match.home_score', 3)
            ->assertJsonPath('data.match.away_score', 2)
            ->assertJsonPath(
                'data.match.status',
                GameStatus::Finished->value
            );

        $this->assertDatabaseHas('matches', [
            'id' => $game->id,
            'home_score' => 3,
            'away_score' => 2,
            'status' => GameStatus::Finished->value,
        ]);
    }

    public function test_an_in_play_match_score_can_be_updated(): void
    {
        $game = Game::query()->firstOrFail();

        $this->updateGame(
            $game,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus::InPlay
        )->assertOk();

        $response = $this->updateGame(
            $game,
            homeScore: 1,
            awayScore: 1,
            status: GameStatus::InPlay
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.match.home_score', 1)
            ->assertJsonPath('data.match.away_score', 1)
            ->assertJsonPath(
                'data.match.status',
                GameStatus::InPlay->value
            );

        $this->assertDatabaseHas('matches', [
            'id' => $game->id,
            'home_score' => 1,
            'away_score' => 1,
            'status' => GameStatus::InPlay->value,
        ]);
    }

    public function test_an_in_play_match_can_be_finished(): void
    {
        $game = Game::query()->firstOrFail();

        $this->updateGame(
            $game,
            homeScore: 2,
            awayScore: 1,
            status: GameStatus::InPlay
        )->assertOk();

        $response = $this->updateGame(
            $game,
            homeScore: 2,
            awayScore: 1,
            status: GameStatus::Finished
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.match.status',
                GameStatus::Finished->value
            );

        $this->assertDatabaseHas('matches', [
            'id' => $game->id,
            'home_score' => 2,
            'away_score' => 1,
            'status' => GameStatus::Finished->value,
        ]);
    }

    public function test_a_finished_result_can_be_corrected(): void
    {
        $game = Game::query()->firstOrFail();

        $this->updateGame(
            $game,
            homeScore: 2,
            awayScore: 1,
            status: GameStatus::Finished
        )->assertOk();

        $response = $this->updateGame(
            $game,
            homeScore: 2,
            awayScore: 2,
            status: GameStatus::Finished
        );

        $response
            ->assertOk()
            ->assertJsonPath('data.match.home_score', 2)
            ->assertJsonPath('data.match.away_score', 2)
            ->assertJsonPath(
                'data.match.status',
                GameStatus::Finished->value
            );

        $this->assertDatabaseHas('matches', [
            'id' => $game->id,
            'home_score' => 2,
            'away_score' => 2,
            'status' => GameStatus::Finished->value,
        ]);
    }

    public function test_a_finished_match_cannot_return_to_in_play(): void
    {
        $game = Game::query()->firstOrFail();

        $this->updateGame(
            $game,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus::Finished
        )->assertOk();

        $response = $this->updateGame(
            $game,
            homeScore: 1,
            awayScore: 1,
            status: GameStatus::InPlay
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');

        $this->assertDatabaseHas('matches', [
            'id' => $game->id,
            'home_score' => 1,
            'away_score' => 0,
            'status' => GameStatus::Finished->value,
        ]);
    }

    public function test_result_update_cannot_move_a_match_back_to_scheduled(): void
    {
        $game = Game::query()->firstOrFail();

        $this->updateGame(
            $game,
            homeScore: 1,
            awayScore: 0,
            status: GameStatus::InPlay
        )->assertOk();

        $response = $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => 1,
                'away_score' => 0,
                'status' => GameStatus::Scheduled->value,
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');

        $this->assertDatabaseHas('matches', [
            'id' => $game->id,
            'home_score' => 1,
            'away_score' => 0,
            'status' => GameStatus::InPlay->value,
        ]);
    }

    public function test_scores_and_status_are_required(): void
    {
        $game = Game::query()->firstOrFail();

        $response = $this->patchJson(
            route('matches.result.update', $game),
            []
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'home_score',
                'away_score',
                'status',
            ]);
    }

    public function test_negative_scores_are_rejected(): void
    {
        $game = Game::query()->firstOrFail();

        $response = $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => -1,
                'away_score' => 0,
                'status' => GameStatus::InPlay->value,
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('home_score');

        $this->assertDatabaseHas('matches', [
            'id' => $game->id,
            'home_score' => null,
            'away_score' => null,
            'status' => GameStatus::Scheduled->value,
        ]);
    }

    public function test_scores_above_database_range_are_rejected(): void
    {
        $game = Game::query()->firstOrFail();

        $response = $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => 65536,
                'away_score' => 0,
                'status' => GameStatus::InPlay->value,
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('home_score');
    }

    public function test_an_invalid_status_is_rejected(): void
    {
        $game = Game::query()->firstOrFail();

        $response = $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => 1,
                'away_score' => 0,
                'status' => 'cancelled',
            ]
        );

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors('status');
    }

    public function test_an_unknown_match_returns_not_found(): void
    {
        $response = $this->patchJson(
            '/api/matches/999999/result',
            [
                'home_score' => 1,
                'away_score' => 0,
                'status' => GameStatus::InPlay->value,
            ]
        );

        $response->assertNotFound();
    }

    public function test_result_update_cannot_modify_match_structure(): void
    {
        $game = Game::query()->firstOrFail();

        $originalHomeTeamId = $game->home_team_id;
        $originalAwayTeamId = $game->away_team_id;
        $originalRoundNumber = $game->round_number;
        $originalKickoffAt = $game->kickoff_at;

        $response = $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => 1,
                'away_score' => 0,
                'status' => GameStatus::InPlay->value,

                'home_team_id' => 999,
                'away_team_id' => 998,
                'round_number' => 99,
                'kickoff_at' => now()->addYear()->toISOString(),
            ]
        );

        $response->assertOk();

        $game->refresh();

        $this->assertSame(
            $originalHomeTeamId,
            $game->home_team_id
        );

        $this->assertSame(
            $originalAwayTeamId,
            $game->away_team_id
        );

        $this->assertSame(
            $originalRoundNumber,
            $game->round_number
        );

        $this->assertEquals(
            $originalKickoffAt,
            $game->kickoff_at
        );
    }

    public function test_repeating_the_same_update_is_idempotent(): void
    {
        $game = Game::query()->firstOrFail();

        $payload = [
            'home_score' => 1,
            'away_score' => 0,
            'status' => GameStatus::InPlay->value,
        ];

        $firstResponse = $this->patchJson(
            route('matches.result.update', $game),
            $payload
        );

        $secondResponse = $this->patchJson(
            route('matches.result.update', $game),
            $payload
        );

        $firstResponse->assertOk();
        $secondResponse->assertOk();

        $this->assertDatabaseHas('matches', [
            'id' => $game->id,
            ...$payload,
        ]);

        $this->assertDatabaseCount('matches', 6);
    }

    public function test_response_contains_recalculated_standings(): void
    {
        $juventus = Team::query()
            ->where('name', 'Juventus')
            ->firstOrFail();

        $game = Game::query()
            ->where('home_team_id', $juventus->id)
            ->firstOrFail();

        $response = $this->updateGame(
            $game,
            homeScore: 2,
            awayScore: 0,
            status: GameStatus::InPlay
        );

        $response
            ->assertOk()
            ->assertJsonCount(4, 'data.standings')
            ->assertJsonPath(
                'data.standings.0.position',
                1
            )
            ->assertJsonPath(
                'data.standings.0.team_id',
                $juventus->id
            )
            ->assertJsonPath(
                'data.standings.0.played',
                1
            )
            ->assertJsonPath(
                'data.standings.0.won',
                1
            )
            ->assertJsonPath(
                'data.standings.0.points',
                3
            )
            ->assertJsonPath(
                'data.standings.0.goal_difference',
                2
            );
    }

    private function updateGame(
        Game $game,
        int $homeScore,
        int $awayScore,
        GameStatus $status
    ): TestResponse {
        return $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => $homeScore,
                'away_score' => $awayScore,
                'status' => $status->value,
            ]
        );
    }
}
