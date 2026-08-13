<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    /** @return array{id:string,type:string,title:string|null,body:string|null,event_id:int|null,read_at:string|null,created_at:string|null} */
    public function toArray(Request $request): array
    {
        return ['id' => $this->id, 'type' => $this->data['type'] ?? class_basename($this->type), 'title' => $this->data['title'] ?? null, 'body' => $this->data['body'] ?? null, 'event_id' => isset($this->data['event_id']) ? (int) $this->data['event_id'] : null, 'read_at' => $this->read_at?->toISOString(), 'created_at' => $this->created_at?->toISOString()];
    }
}
