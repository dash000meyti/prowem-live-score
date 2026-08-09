<?php

namespace App\Actions\Matches;

use App\Enums\GameStatus;
use App\Exceptions\InvalidGameStatusTransition;
use App\Models\Game;
use App\Models\Team;
use App\Services\Tournament\StandingsCalculator;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class UpdateMatchResult
{
    public function __construct(
        private readonly StandingsCalculator $standingsCalculator
    ) {
    }

    /**
     * @return array{
     *     game: Game,
     *     standings: Collection
     * }
     */
    public function execute(
        Game $game,
        int $homeScore,
        int $awayScore,
        GameStatus $status
    ): array {
        $updatedGame = DB::transaction(
            function () use (
                $game,
                $homeScore,
                $awayScore,
                $status
            ): Game {
                $lockedGame = Game::query()
                    ->whereKey($game->getKey())
                    ->lockForUpdate()
                    ->firstOrFail();

                $this->assertTransitionAllowed(
                    $lockedGame->status,
                    $status
                );

                $lockedGame->update([
                    'home_score' => $homeScore,
                    'away_score' => $awayScore,
                    'status' => $status,
                ]);

                return $lockedGame;
            },
            3
        );

        $updatedGame
            ->refresh()
            ->load([
                'homeTeam',
                'awayTeam',
            ]);

        $standings = $this->standingsCalculator->calculate(
            Team::query()->get(),
            Game::query()->get()
        );

        return [
            'game' => $updatedGame,
            'standings' => $standings,
        ];
    }

    private function assertTransitionAllowed(
        GameStatus $current,
        GameStatus $next
    ): void {
        if ($current->canTransitionTo($next)) {
            return;
        }

        throw new InvalidGameStatusTransition(
            sprintf(
                'Cannot transition a match from "%s" to "%s".',
                $current->value,
                $next->value
            )
        );
    }
}
