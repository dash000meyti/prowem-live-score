<?php

namespace Tests\Feature;

use App\Models\Team;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class MatchDatabaseConstraintsTest extends TestCase
{
    use RefreshDatabase;

    public function test_database_rejects_an_unknown_match_status(): void
    {
        [$homeTeamId, $awayTeamId] = $this->createTeamIds();

        $this->expectException(QueryException::class);

        DB::table('matches')->insert([
            'home_team_id' => $homeTeamId,
            'away_team_id' => $awayTeamId,
            'round_number' => 1,
            'home_score' => 0,
            'away_score' => 0,
            'status' => 'cancelled',
        ]);
    }

    public function test_database_rejects_scores_for_a_scheduled_match(): void
    {
        [$homeTeamId, $awayTeamId] = $this->createTeamIds();

        $this->expectException(QueryException::class);

        DB::table('matches')->insert([
            'home_team_id' => $homeTeamId,
            'away_team_id' => $awayTeamId,
            'round_number' => 1,
            'home_score' => 0,
            'away_score' => 0,
            'status' => 'scheduled',
        ]);
    }

    public function test_database_rejects_a_live_match_without_scores(): void
    {
        [$homeTeamId, $awayTeamId] = $this->createTeamIds();

        $this->expectException(QueryException::class);

        DB::table('matches')->insert([
            'home_team_id' => $homeTeamId,
            'away_team_id' => $awayTeamId,
            'round_number' => 1,
            'home_score' => null,
            'away_score' => null,
            'status' => 'in_play',
        ]);
    }

    public function test_database_rejects_a_finished_match_without_scores(): void
    {
        [$homeTeamId, $awayTeamId] = $this->createTeamIds();

        $this->expectException(QueryException::class);

        DB::table('matches')->insert([
            'home_team_id' => $homeTeamId,
            'away_team_id' => $awayTeamId,
            'round_number' => 1,
            'home_score' => null,
            'away_score' => null,
            'status' => 'finished',
        ]);
    }

    /**
     * @return array{0: int, 1: int}
     */
    private function createTeamIds(): array
    {
        $homeTeam = Team::query()->create([
            'name' => 'Home Team',
        ]);

        $awayTeam = Team::query()->create([
            'name' => 'Away Team',
        ]);

        return [
            $homeTeam->id,
            $awayTeam->id,
        ];
    }
}
