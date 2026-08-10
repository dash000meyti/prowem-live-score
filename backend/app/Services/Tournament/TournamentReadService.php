<?php

namespace App\Services\Tournament;

use App\Models\Game;
use App\Models\Team;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;
use Illuminate\Support\Collection;

/**
 * @phpstan-import-type StandingRow from StandingsCalculator
 */
class TournamentReadService
{
    public function __construct(
        private readonly StandingsCalculator $standingsCalculator
    ) {}

    /**
     * @return EloquentCollection<int, Game>
     */
    public function listMatches(): EloquentCollection
    {
        return Game::query()
            ->with([
                'homeTeam',
                'awayTeam',
            ])
            ->orderBy('round_number')
            ->orderBy('id')
            ->get();
    }

    /**
     * @return Collection<int, StandingRow>
     */
    public function getStandings(): Collection
    {
        $teams = $this->getTeams();

        $games = Game::query()
            ->orderBy('id')
            ->get();

        return $this->standingsCalculator->calculate(
            $teams,
            $games
        );
    }

    /**
     * @return array{
     *     teams: EloquentCollection<int, Team>,
     *     matches: EloquentCollection<int, Game>,
     *     standings: Collection<int, StandingRow>
     * }
     */
    public function getSnapshot(): array
    {
        $teams = $this->getTeams();

        $matches = $this->listMatches();

        $standings = $this->standingsCalculator->calculate(
            $teams,
            $matches
        );

        return [
            'teams' => $teams,
            'matches' => $matches,
            'standings' => $standings,
        ];
    }

    /**
     * @return EloquentCollection<int, Team>
     */
    private function getTeams(): EloquentCollection
    {
        return Team::query()
            ->orderBy('id')
            ->get();
    }
}
