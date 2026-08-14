<?php

namespace App\Http\Resources;

use App\Models\Incident;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class IncidentResource extends JsonResource
{
    /** @return array{id:int,event_id:int,fixture_id:int|null,venue_id:int|null,fixture:mixed,venue:mixed,type:string,category:string,severity:string,status:string,title:string,description:string,started_at:string,acknowledged_at:string|null,resolved_at:string|null,resolution:string|null,metadata:object|null,ticket:mixed} */
    public function toArray(Request $request): array
    {
        /** @var Incident $incident */
        $incident = $this->resource;

        return ['id' => (int) $incident->id, 'event_id' => (int) $incident->event_id, 'fixture_id' => $incident->fixture_id ? (int) $incident->fixture_id : null, 'venue_id' => $incident->venue_id ? (int) $incident->venue_id : null, 'fixture' => $incident->relationLoaded('fixture') && $incident->fixture ? ['id' => (int) $incident->fixture->id, 'number' => (int) $incident->fixture->number, 'kickoff_at' => $incident->fixture->kickoff_at->toISOString()] : null, 'venue' => $incident->relationLoaded('venue') && $incident->venue ? ['id' => (int) $incident->venue->id, 'name' => $incident->venue->name] : null, 'type' => $incident->type->value, 'category' => $incident->category, 'severity' => $incident->severity->value, 'status' => $incident->status->value, 'title' => $incident->title, 'description' => $incident->description, 'started_at' => $incident->started_at->toISOString(), 'acknowledged_at' => $incident->acknowledged_at?->toISOString(), 'resolved_at' => $incident->resolved_at?->toISOString(), 'resolution' => $incident->resolution, 'metadata' => $incident->metadata === null ? null : (object) $incident->metadata, 'ticket' => new SupportTicketResource($incident->relationLoaded('ticket') ? $incident->ticket : null)];
    }
}
