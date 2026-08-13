<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class IncidentResource extends JsonResource
{
    /** @return array{id:int,event_id:int,fixture_id:int|null,venue_id:int|null,type:string,category:string,severity:string,status:string,title:string,description:string,started_at:string,acknowledged_at:string|null,resolved_at:string|null,resolution:string|null,metadata:object|null,ticket:mixed} */
    public function toArray(Request $request): array
    {
        return ['id' => (int) $this->id, 'event_id' => (int) $this->event_id, 'fixture_id' => $this->fixture_id ? (int) $this->fixture_id : null, 'venue_id' => $this->venue_id ? (int) $this->venue_id : null, 'type' => $this->type->value, 'category' => $this->category, 'severity' => $this->severity->value, 'status' => $this->status->value, 'title' => $this->title, 'description' => $this->description, 'started_at' => $this->started_at->toISOString(), 'acknowledged_at' => $this->acknowledged_at?->toISOString(), 'resolved_at' => $this->resolved_at?->toISOString(), 'resolution' => $this->resolution, 'metadata' => $this->metadata === null ? null : (object) $this->metadata, 'ticket' => new SupportTicketResource($this->whenLoaded('ticket'))];
    }
}
