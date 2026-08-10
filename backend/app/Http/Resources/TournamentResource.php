<?php

namespace App\Http\Resources;

use App\Models\Game;
use App\Models\Team;
use App\Services\Tournament\StandingsCalculator;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Collection;

/**
 * @phpstan-import-type StandingRow from StandingsCalculator
 */
class TournamentResource extends JsonResource
{
    /**
     * @return array{
     *     teams: AnonymousResourceCollection,
     *     matches: AnonymousResourceCollection,
     *     standings: AnonymousResourceCollection
     * }
     */
    public function toArray(Request $request): array
    {
        /**
         * @var array{
         *     teams: Collection<int, Team>,
         *     matches: Collection<int, Game>,
         *     standings: Collection<int, StandingRow>
         * } $tournament
         */
        $tournament = $this->resource;

        return [
            'teams' => TeamResource::collection(
                $tournament['teams']
            ),

            'matches' => GameResource::collection(
                $tournament['matches']
            ),

            'standings' => StandingResource::collection(
                $tournament['standings']
            ),
        ];
    }
}
