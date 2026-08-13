<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \ArrayAccess<string,mixed> */
class EventCareOverviewResource extends JsonResource
{
    /** @return array{event:array{id:int,external_reference:string|null,name:string,status:string,starts_at:string,ends_at:string,completed_at:string|null,venue:array{id:int,name:string}|null,team_count:int,field_count:int},readiness:array{status:string,score:int,critical_blockers_count:int,actions_required_count:int,dimensions:list<array{key:string,label:string,status:string,score:int,ready:int,total:int,actions_required:int}>,checks_count:int},readiness_dimensions:list<array{key:string,label:string,status:string,score:int,ready:int,total:int,actions_required:int}>,needs_attention:list<ReadinessCheckResource>,open_critical_incidents:list<IncidentResource>,open_tickets:list<SupportTicketResource>,next_matches:list<array{id:int,number:int,kickoff_at:string,status:string,field:string|null,home_team:array{id:int,name:string}|null,away_team:array{id:int,name:string}|null}>,recent_activity:list<ActivityResource>} */
    public function toArray(Request $request): array
    {
        return $this->resource;
    }
}
