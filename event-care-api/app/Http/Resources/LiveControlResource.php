<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LiveControlResource extends JsonResource
{
    /** @return array{event:array{id:int,status:string},progress:array{completed:int,total:int},live_matches:list<array{id:int,event_id:int,venue_id:int|null,referee_id:int|null,home_team_id:int,away_team_id:int,number:int,kickoff_at:string,status:string,delay_minutes:int}>,next_matches:list<array{id:int,event_id:int,venue_id:int|null,referee_id:int|null,home_team_id:int,away_team_id:int,number:int,kickoff_at:string,status:string,delay_minutes:int}>,delayed_matches:list<array{id:int,event_id:int,venue_id:int|null,referee_id:int|null,home_team_id:int,away_team_id:int,number:int,kickoff_at:string,status:string,delay_minutes:int}>,operational_incidents:list<IncidentResource>,system_status:array{status:string,score:int,critical_blockers_count:int,actions_required_count:int,dimensions:list<array{key:string,label:string,status:string,score:int,ready:int,total:int,actions_required:int}>,checks_count:int}} */
    public function toArray(Request $request): array
    {
        return $this->resource;
    }
}
