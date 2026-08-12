<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EventListResource extends JsonResource
{
    /** @return array{id:int,external_reference:string|null,name:string,status:string,starts_at:string,ends_at:string,venue:array{id:int,name:string}|null,teams_count:int,fields_count:int,readiness:array{status:string,score:int,critical_blockers_count:int,actions_required_count:int},open_incidents_count:int,critical_incidents_count:int,open_tickets_count:int} */
    public function toArray(Request $request): array
    {
        return ['id' => (int) $this->id, 'external_reference' => $this->external_reference, 'name' => $this->name, 'status' => $this->status->value, 'starts_at' => $this->starts_at->toISOString(), 'ends_at' => $this->ends_at->toISOString(), 'venue' => $this->venue_summary, 'teams_count' => (int) $this->teams_count, 'fields_count' => (int) $this->venues_count, 'readiness' => $this->readiness_summary, 'open_incidents_count' => (int) $this->open_incidents_count, 'critical_incidents_count' => (int) $this->critical_incidents_count, 'open_tickets_count' => (int) $this->open_tickets_count];
    }
}
