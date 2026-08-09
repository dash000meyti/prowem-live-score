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
            Team::pluck('name')->all()
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
            Game::where('status', GameStatus::Scheduled->value)->count()
        );

        $this->assertSame(
            0,
            Game::whereNotNull('home_score')
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
}
