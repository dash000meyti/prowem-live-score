<?php

namespace App\Services\Tournament;

use App\Enums\GameStatus;
use App\Models\Game;
use App\Models\Team;
use Illuminate\Support\Collection;
use LogicException;

class StandingsCalculator
{
    /**
     * @param Collection<int, Team> $teams
     * @param Collection<int, Game> $games
     *
     * @return Collection<int, array{
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
     * }>
     */
    public function calculate(Collection $teams, Collection $games): Collection
    {
        $standings = $this->initializeStandings($teams);

        foreach ($games as $game) {
            if (! $this->countsTowardsStandings($game)) {
                continue;
            }

            $this->assertValidScoredGame($game, $standings);

            $this->applyGame($standings, $game);
        }

        return $this->rank($standings);
    }

    /**
     * @param Collection<int, Team> $teams
     * @return array<int, array<string, int>>
     */
    private function initializeStandings(Collection $teams): array
    {
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

    private function countsTowardsStandings(Game $game): bool
    {
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
     * @param array<int, array<string, int>> $standings
     */
    private function assertValidScoredGame(Game $game, array $standings): void
    {
        if ($game->home_score < 0 || $game->away_score < 0) {
            throw new LogicException(
                'Match scores cannot be negative.'
            );
        }

        if ($game->home_score === null || $game->away_score === null) {
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
     * @param array<int, array<string, int>> $standings
     */
    private function applyGame(array &$standings, Game $game): void
    {
        $homeTeamId = $game->home_team_id;
        $awayTeamId = $game->away_team_id;

        $standings[$homeTeamId]['played']++;
        $standings[$awayTeamId]['played']++;

        $standings[$homeTeamId]['goals_for'] += $game->home_score;
        $standings[$homeTeamId]['goals_against'] += $game->away_score;

        $standings[$awayTeamId]['goals_for'] += $game->away_score;
        $standings[$awayTeamId]['goals_against'] += $game->home_score;

        if ($game->home_score > $game->away_score) {
            $this->applyWin($standings, $homeTeamId, $awayTeamId);

            return;
        }

        if ($game->away_score > $game->home_score) {
            $this->applyWin($standings, $awayTeamId, $homeTeamId);

            return;
        }

        $this->applyDraw($standings, $homeTeamId, $awayTeamId);
    }

    /**
     * @param array<int, array<string, int>> $standings
     */
    private function applyWin(
        array &$standings,
        int $winnerId,
        int $loserId
    ): void {
        $standings[$winnerId]['won']++;
        $standings[$winnerId]['points'] += 3;

        $standings[$loserId]['lost']++;
    }

    /**
     * @param array<int, array<string, int>> $standings
     */
    private function applyDraw(
        array &$standings,
        int $homeTeamId,
        int $awayTeamId
    ): void {
        $standings[$homeTeamId]['drawn']++;
        $standings[$awayTeamId]['drawn']++;

        $standings[$homeTeamId]['points']++;
        $standings[$awayTeamId]['points']++;
    }

    /**
     * @param array<int, array<string, int>> $standings
     */
    private function rank(array $standings): Collection
    {
        foreach ($standings as &$standing) {
            $standing['goal_difference'] =
                $standing['goals_for'] - $standing['goals_against'];
        }

        unset($standing);

        usort($standings, [$this, 'compare']);

        return collect($standings)
            ->values()
            ->map(function (array $standing, int $index): array {
                $standing['position'] = $index + 1;

                return $standing;
            });
    }

    private function compare(array $first, array $second): int
    {
        return ($second['points'] <=> $first['points'])
            ?: ($second['goal_difference'] <=> $first['goal_difference'])
                ?: ($second['goals_for'] <=> $first['goals_for'])
                    ?: ($first['team_id'] <=> $second['team_id']);
    }
}
