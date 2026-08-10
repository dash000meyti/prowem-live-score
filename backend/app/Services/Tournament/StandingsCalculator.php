<?php

namespace App\Services\Tournament;

use App\Enums\GameStatus;
use App\Models\Game;
use App\Models\Team;
use Illuminate\Support\Collection;
use LogicException;

/**
 * @phpstan-type StandingRow array{
 *     position: int,
 *     team_id: int,
 *     played: int,
 *     won: int,
 *     drawn: int,
 *     lost: int,
 *     goals_for: int,
 *     goals_against: int,
 *     goal_difference: int,
 *     points: int
 * }
 */
class StandingsCalculator
{
    private const int POINTS_FOR_WIN = 3;

    private const int POINTS_FOR_DRAW = 1;

    /**
     * @param  Collection<int, Team>  $teams
     * @param  Collection<int, Game>  $games
     * @return Collection<int, StandingRow>
     */
    public function calculate(
        Collection $teams,
        Collection $games
    ): Collection {
        $standings = $this->initializeStandings($teams);

        foreach ($games as $game) {
            if (! $this->countsTowardsStandings($game)) {
                continue;
            }

            $this->assertValidScoredGame(
                $game,
                $standings
            );

            $standings = $this->applyGame(
                $standings,
                $game
            );
        }

        return $this->rank($standings);
    }

    /**
     * @param  Collection<int, Team>  $teams
     * @return array<int, StandingRow>
     */
    private function initializeStandings(
        Collection $teams
    ): array {
        $standings = [];

        foreach ($teams as $team) {
            $standings[$team->id] = [
                'position' => 0,
                'team_id' => $team->id,
                'played' => 0,
                'won' => 0,
                'drawn' => 0,
                'lost' => 0,
                'goals_for' => 0,
                'goals_against' => 0,
                'goal_difference' => 0,
                'points' => 0,
            ];
        }

        return $standings;
    }

    private function countsTowardsStandings(
        Game $game
    ): bool {
        return in_array(
            $game->status,
            [
                GameStatus::InPlay,
                GameStatus::Finished,
            ],
            true
        );
    }

    /**
     * @param  array<int, StandingRow>  $standings
     */
    private function assertValidScoredGame(
        Game $game,
        array $standings
    ): void {
        if (
            $game->home_score === null
            || $game->away_score === null
        ) {
            throw new LogicException(
                'An in-play or finished match must have a score.'
            );
        }

        if (
            ! isset($standings[$game->home_team_id])
            || ! isset($standings[$game->away_team_id])
        ) {
            throw new LogicException(
                'Every match team must exist in the standings.'
            );
        }

        if ($game->home_team_id === $game->away_team_id) {
            throw new LogicException(
                'A team cannot play against itself.'
            );
        }
    }

    /**
     * @param  array<int, StandingRow>  $standings
     * @return array<int, StandingRow>
     */
    private function applyGame(
        array $standings,
        Game $game
    ): array {
        $homeTeamId = $game->home_team_id;
        $awayTeamId = $game->away_team_id;

        $homeStanding = $standings[$homeTeamId];
        $awayStanding = $standings[$awayTeamId];

        $homeStanding['played']++;
        $awayStanding['played']++;

        $homeStanding['goals_for'] += $game->home_score;
        $homeStanding['goals_against'] += $game->away_score;

        $awayStanding['goals_for'] += $game->away_score;
        $awayStanding['goals_against'] += $game->home_score;

        if ($game->home_score > $game->away_score) {
            $homeStanding['won']++;
            $homeStanding['points'] += self::POINTS_FOR_WIN;

            $awayStanding['lost']++;
        } elseif ($game->away_score > $game->home_score) {
            $awayStanding['won']++;
            $awayStanding['points'] += self::POINTS_FOR_WIN;

            $homeStanding['lost']++;
        } else {
            $homeStanding['drawn']++;
            $awayStanding['drawn']++;

            $homeStanding['points'] += self::POINTS_FOR_DRAW;
            $awayStanding['points'] += self::POINTS_FOR_DRAW;
        }

        $standings[$homeTeamId] = $homeStanding;
        $standings[$awayTeamId] = $awayStanding;

        return $standings;
    }

    /**
     * @param  array<int, StandingRow>  $standings
     * @return Collection<int, StandingRow>
     */
    private function rank(
        array $standings
    ): Collection {
        foreach ($standings as $teamId => $standing) {
            $standing['goal_difference'] =
                $standing['goals_for']
                - $standing['goals_against'];

            $standings[$teamId] = $standing;
        }

        usort(
            $standings,
            [$this, 'compare']
        );

        return collect($standings)
            ->values()
            ->map(
                function (
                    array $standing,
                    int $index
                ): array {
                    $standing['position'] = $index + 1;

                    return $standing;
                }
            );
    }

    /**
     * @param  StandingRow  $first
     * @param  StandingRow  $second
     */
    private function compare(
        array $first,
        array $second
    ): int {
        return ($second['points'] <=> $first['points'])
            ?: ($second['goal_difference'] <=> $first['goal_difference'])
                ?: ($second['goals_for'] <=> $first['goals_for'])
                    ?: ($first['team_id'] <=> $second['team_id']);
    }
}
