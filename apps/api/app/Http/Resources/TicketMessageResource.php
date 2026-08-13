<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TicketMessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return ['id' => (int) $this->id, 'ticket_id' => (int) $this->ticket_id, 'author' => $this->author?->only(['id', 'name', 'role']), 'visibility' => $this->visibility, 'body' => $this->body, 'created_at' => $this->created_at?->toISOString()];
    }
}
