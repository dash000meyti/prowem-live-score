<?php

namespace App\Http\Resources;

use App\Models\Game;
use App\Services\Tournament\StandingsCalculator;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Collection;

/**
 * @phpstan-import-type StandingRow from StandingsCalculator
 */
class MatchUpdateResource extends JsonResource
{
    /**
     * @return array{
     *     update_id: string,
     *     occurred_at: string,
     *     match: GameResource,
     *     standings: AnonymousResourceCollection
     * }
     */
    public function toArray(Request $request): array
    {
        /**
         * @var array{
         *     update_id: string,
         *     occurred_at: string,
         *     game: Game,
         *     standings: Collection<int, StandingRow>
         * } $payload
         */
        $payload = $this->resource;

        return [
            'update_id' => $payload['update_id'],
            'occurred_at' => $payload['occurred_at'],

            'match' => new GameResource(
                $payload['game']
            ),

            'standings' => StandingResource::collection(
                $payload['standings']
            ),
        ];
    }
}
