<?php

namespace App\Http\Resources;

use App\Models\SupportTicket;
use App\Services\SlaCalculator;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SupportTicketResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        /** @var SupportTicket $ticket */
        $ticket = $this->resource;
        $location = $ticket->relationLoaded('venue') ? $ticket->venue?->name : null;
        if (! $location && $ticket->relationLoaded('fixture') && $ticket->fixture?->relationLoaded('venue')) {
            $location = $ticket->fixture->venue?->name;
        }

        return ['id' => (int) $ticket->id, 'reference' => $ticket->reference ?? sprintf('EC-%06d', $ticket->id), 'event' => ['id' => (int) $ticket->event_id, 'name' => $ticket->relationLoaded('event') ? $ticket->event?->name : null], 'incident' => $ticket->incident?->only(['id', 'category', 'title']), 'affected_service' => $ticket->affected_service, 'location' => $location, 'priority' => $ticket->priority->value, 'status' => $ticket->status->value, 'subject' => $ticket->subject, 'description' => $ticket->description, 'assignee' => $ticket->assignee?->only(['id', 'name']), 'created_at' => $ticket->created_at?->toISOString(), 'updated_at' => $ticket->updated_at?->toISOString(), 'first_response_at' => $ticket->first_response_at?->toISOString(), 'sla_due_at' => $ticket->sla_due_at->toISOString(), 'sla_status' => app(SlaCalculator::class)->state($ticket->first_response_at, $ticket->sla_due_at), 'sla_remaining_seconds' => $ticket->first_response_at || now()->greaterThanOrEqualTo($ticket->sla_due_at) ? 0 : (int) now()->diffInSeconds($ticket->sla_due_at), 'resolved_at' => $ticket->resolved_at?->toISOString(), 'resolution' => $ticket->resolution, 'resolution_code' => $ticket->resolution_code];
    }
}
