<?php

namespace App\Http\Resources;

use App\Models\Team;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class TeamResource extends JsonResource
{
    /**
     * @return array{
     *     id: int,
     *     name: string,
     *     logo_url: string|null
     * }
     */
    public function toArray(Request $request): array
    {
        /** @var Team $team */
        $team = $this->resource;

        return [
            'id' => $team->id,
            'name' => $team->name,
            'logo_url' => $team->logo !== null
                ? Storage::disk('public')->url($team->logo)
                : null,
        ];
    }
}
