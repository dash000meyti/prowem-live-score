<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EventResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return ['id' => $this->id, 'external_reference' => $this->external_reference, 'name' => $this->name, 'status' => $this->status->value, 'starts_at' => $this->starts_at->toISOString(), 'ends_at' => $this->ends_at->toISOString(), 'completed_at' => $this->completed_at?->toISOString()];
    }
}
