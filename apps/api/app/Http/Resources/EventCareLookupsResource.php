<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \ArrayAccess<string,mixed> */
class EventCareLookupsResource extends JsonResource
{
    /** @return array{venues: list<array{id:int,name:string}>, fixtures: list<array{id:int,number:int,kickoff_at:string,status:string,venue_id:int|null,home_team:array{id:int,name:string}|null,away_team:array{id:int,name:string}|null}>, staff: list<array{id:int,name:string,role:string}>} */
    public function toArray(Request $request): array
    {
        return $this->resource;
    }
}
