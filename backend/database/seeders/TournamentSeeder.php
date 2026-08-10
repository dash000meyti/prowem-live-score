<?php

namespace Database\Seeders;

use App\Enums\GameStatus;
use App\Models\Game;
use App\Models\Team;
use App\Services\Tournament\RoundRobinScheduler;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class TournamentSeeder extends Seeder
{
    private const array TEAMS = [
        'Juventus',
        'Inter',
        'AC Milan',
        'AS Roma',
    ];

    public function run(RoundRobinScheduler $scheduler): void
    {
        DB::transaction(function () use ($scheduler): void {
            $teams = collect(self::TEAMS)
                ->map(
                    fn (string $name) => Team::firstOrCreate(
                        ['name' => $name],
                        ['logo' => null],
                    )
                );

            $schedule = $scheduler->generate($teams);

            if ($teams->count() !== 4 || count($schedule) !== 6) {
                throw new RuntimeException(
                    'The tournament must contain exactly four teams and six matches.'
                );
            }

            foreach ($schedule as $match) {
                Game::firstOrCreate(
                    [
                        'home_team_id' => $match['home_team_id'],
                        'away_team_id' => $match['away_team_id'],
                    ],
                    [
                        'round_number' => $match['round_number'],
                        'home_score' => null,
                        'away_score' => null,
                        'status' => GameStatus::Scheduled,
                    ],
                );
            }
        });
    }
}
