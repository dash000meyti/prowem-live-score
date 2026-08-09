<?php

namespace App\Services\Tournament;

use App\Models\Team;
use Illuminate\Support\Collection;
use InvalidArgumentException;

class RoundRobinScheduler
{
    /**
     * @param Collection<int, Team> $teams
     * @return array<int, array{
     *     round_number: int,
     *     home_team_id: int,
     *     away_team_id: int
     * }>
     */
    public function generate(Collection $teams): array
    {
        if ($teams->count() < 2) {
            throw new InvalidArgumentException(
                'At least two teams are required to generate fixtures.'
            );
        }

        $rotation = $teams->values()->all();

        // For an odd number of teams, add a bye slot.
        if (count($rotation) % 2 !== 0) {
            $rotation[] = null;
        }

        $slotCount = count($rotation);
        $roundCount = $slotCount - 1;
        $matchesPerRound = intdiv($slotCount, 2);

        $fixtures = [];

        for ($roundIndex = 0; $roundIndex < $roundCount; $roundIndex++) {
            for ($pairIndex = 0; $pairIndex < $matchesPerRound; $pairIndex++) {
                $homeTeam = $rotation[$pairIndex];
                $awayTeam = $rotation[$slotCount - 1 - $pairIndex];

                // A null slot represents a bye.
                if ($homeTeam === null || $awayTeam === null) {
                    continue;
                }

                // Alternate the first pairing to balance home/away allocation.
                if ($pairIndex === 0 && $roundIndex % 2 === 1) {
                    [$homeTeam, $awayTeam] = [$awayTeam, $homeTeam];
                }

                $fixtures[] = [
                    'round_number' => $roundIndex + 1,
                    'home_team_id' => $homeTeam->id,
                    'away_team_id' => $awayTeam->id,
                ];
            }

            $rotation = $this->rotate($rotation);
        }

        return $fixtures;
    }

    /**
     * Keep the first slot fixed and rotate all remaining slots clockwise.
     *
     * @param array<int, Team|null> $teams
     * @return array<int, Team|null>
     */
    private function rotate(array $teams): array
    {
        $fixedTeam = array_shift($teams);
        $lastTeam = array_pop($teams);

        array_unshift($teams, $lastTeam);
        array_unshift($teams, $fixedTeam);

        return $teams;
    }
}
