<?php

namespace Tests\Feature;

use App\Enums\GameStatus;
use App\Exceptions\TeamAlreadyInLiveMatch;
use App\Models\Game;
use App\Models\Team;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MatchConflictResponseTest extends TestCase
{
    use RefreshDatabase;

    public function test_live_match_conflict_has_a_stable_machine_readable_error_code(): void
    {
        $juventus = Team::query()->create([
            'name' => 'Juventus',
        ]);

        $inter = Team::query()->create([
            'name' => 'Inter',
        ]);

        $milan = Team::query()->create([
            'name' => 'AC Milan',
        ]);

        $liveGame = Game::query()->create([
            'home_team_id' => $inter->id,
            'away_team_id' => $milan->id,
            'round_number' => 1,
            'home_score' => 1,
            'away_score' => 0,
            'status' => GameStatus::InPlay,
        ]);

        $candidate = Game::query()->create([
            'home_team_id' => $milan->id,
            'away_team_id' => $juventus->id,
            'round_number' => 2,
            'home_score' => null,
            'away_score' => null,
            'status' => GameStatus::Scheduled,
        ]);

        $response = $this->patchJson(
            route('matches.result.update', $candidate),
            [
                'home_score' => 0,
                'away_score' => 0,
                'status' => GameStatus::InPlay->value,
            ]
        );

        $response
            ->assertStatus(409)
            ->assertJsonPath(
                'code',
                TeamAlreadyInLiveMatch::CODE
            )
            ->assertJsonPath(
                'conflict.match_id',
                $liveGame->id
            );

        $candidate->refresh();

        $this->assertSame(
            GameStatus::Scheduled,
            $candidate->status
        );

        $this->assertNull($candidate->home_score);
        $this->assertNull($candidate->away_score);
    }
}
