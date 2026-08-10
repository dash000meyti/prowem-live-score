<?php

namespace App\Http\Resources;

use App\Models\Game;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GameResource extends JsonResource
{
    /**
     * @return array{
     *     id: int,
     *     round_number: int,
     *     home_team_id: int,
     *     away_team_id: int,
     *     home_team: TeamResource,
     *     away_team: TeamResource,
     *     home_score: int|null,
     *     away_score: int|null,
     *     status: string,
     *     kickoff_at: string|null
     * }
     */
    public function toArray(Request $request): array
    {
        /** @var Game $game */
        $game = $this->resource;

        return [
            'id' => $game->id,
            'round_number' => $game->round_number,

            'home_team_id' => $game->home_team_id,
            'away_team_id' => $game->away_team_id,

            'home_team' => new TeamResource(
                $this->whenLoaded('homeTeam')
            ),

            'away_team' => new TeamResource(
                $this->whenLoaded('awayTeam')
            ),

            'home_score' => $game->home_score,
            'away_score' => $game->away_score,

            'status' => $game->status->value,

            'kickoff_at' => $game->kickoff_at?->toISOString(),
        ];
    }
}
