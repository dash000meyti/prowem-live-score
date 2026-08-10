<?php

namespace App\Http\Resources;

use App\Services\Tournament\StandingsCalculator;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @phpstan-import-type StandingRow from StandingsCalculator
 */
class StandingResource extends JsonResource
{
    /**
     * @return StandingRow
     */
    public function toArray(Request $request): array
    {
        /** @var StandingRow $standing */
        $standing = $this->resource;

        return [
            'position' => $standing['position'],
            'team_id' => $standing['team_id'],

            'played' => $standing['played'],
            'won' => $standing['won'],
            'drawn' => $standing['drawn'],
            'lost' => $standing['lost'],

            'goals_for' => $standing['goals_for'],
            'goals_against' => $standing['goals_against'],
            'goal_difference' => $standing['goal_difference'],

            'points' => $standing['points'],
        ];
    }
}
