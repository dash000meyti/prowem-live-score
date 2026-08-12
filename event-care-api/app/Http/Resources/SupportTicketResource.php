<?php

namespace App\Http\Resources;

use App\Services\SlaCalculator;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SupportTicketResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return ['id' => (int) $this->id, 'reference' => $this->reference ?? sprintf('EC-%06d', $this->id), 'event' => ['id' => (int) $this->event_id, 'name' => $this->relationLoaded('event') ? $this->event?->name : null], 'incident' => $this->incident?->only(['id', 'category', 'title']), 'affected_service' => $this->affected_service, 'priority' => $this->priority->value, 'status' => $this->status->value, 'subject' => $this->subject, 'description' => $this->description, 'assignee' => $this->assignee?->only(['id', 'name']), 'created_at' => $this->created_at?->toISOString(), 'first_response_at' => $this->first_response_at?->toISOString(), 'sla_due_at' => $this->sla_due_at->toISOString(), 'sla_status' => app(SlaCalculator::class)->state($this->first_response_at, $this->sla_due_at), 'resolved_at' => $this->resolved_at?->toISOString(), 'resolution' => $this->resolution, 'resolution_code' => $this->resolution_code];
    }
}
