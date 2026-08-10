<?php

namespace Tests\Feature;

use App\Enums\GameStatus;
use App\Models\Game;
use App\Models\Team;
use Database\Seeders\TournamentSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TournamentSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_seeds_the_expected_tournament(): void
    {
        $this->seed(TournamentSeeder::class);

        $this->assertDatabaseCount('teams', 4);
        $this->assertDatabaseCount('matches', 6);

        $this->assertEqualsCanonicalizing(
            [
                'Juventus',
                'Inter',
                'AC Milan',
                'AS Roma',
            ],
            Team::query()
                ->pluck('name')
                ->all()
        );

        $this->assertSame(
            3,
            Game::query()
                ->distinct()
                ->count('round_number')
        );

        $matchesPerRound = Game::query()
            ->selectRaw('round_number, COUNT(*) as match_count')
            ->groupBy('round_number')
            ->orderBy('round_number')
            ->pluck('match_count')
            ->map(fn ($count) => (int) $count)
            ->all();

        $this->assertSame(
            [2, 2, 2],
            $matchesPerRound
        );

        $this->assertSame(
            6,
            Game::query()
                ->where(
                    'status',
                    GameStatus::Scheduled->value
                )
                ->count()
        );

        $this->assertSame(
            0,
            Game::query()
                ->whereNotNull('home_score')
                ->orWhereNotNull('away_score')
                ->count()
        );
    }

    public function test_it_can_be_run_multiple_times_without_creating_duplicates(): void
    {
        $this->seed(TournamentSeeder::class);
        $this->seed(TournamentSeeder::class);

        $this->assertDatabaseCount('teams', 4);
        $this->assertDatabaseCount('matches', 6);
    }

    public function test_rerunning_the_seeder_preserves_existing_match_results(): void
    {
        $this->seed(TournamentSeeder::class);

        $game = Game::query()
            ->orderBy('id')
            ->firstOrFail();

        $game->update([
            'home_score' => 2,
            'away_score' => 1,
            'status' => GameStatus::Finished,
        ]);

        $this->seed(TournamentSeeder::class);

        $game->refresh();

        $this->assertSame(
            2,
            $game->home_score
        );

        $this->assertSame(
            1,
            $game->away_score
        );

        $this->assertSame(
            GameStatus::Finished,
            $game->status
        );

        $this->assertDatabaseCount('teams', 4);
        $this->assertDatabaseCount('matches', 6);
    }

    public function test_rerunning_the_seeder_preserves_existing_team_data(): void
    {
        $this->seed(TournamentSeeder::class);

        $team = Team::query()
            ->where('name', 'Juventus')
            ->firstOrFail();

        $team->update([
            'logo' => 'teams/juventus.png',
        ]);

        $this->seed(TournamentSeeder::class);

        $team->refresh();

        $this->assertSame(
            'teams/juventus.png',
            $team->logo
        );

        $this->assertDatabaseCount('teams', 4);
    }
}
