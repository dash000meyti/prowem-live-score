<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ActivityResource extends JsonResource
{
    /** @return array{id:int,type:string,title:string,description:string,entity:array{type:string|null,id:int|null},actor:array{id:int,name:string}|null,context:object|null,occurred_at:string} */
    public function toArray(Request $request): array
    {
        return ['id' => (int) $this->id, 'type' => $this->type, 'title' => ucwords(str_replace('_', ' ', $this->type)), 'description' => $this->description, 'entity' => ['type' => $this->subject_type, 'id' => $this->subject_id ? (int) $this->subject_id : null], 'actor' => $this->actor?->only(['id', 'name']), 'context' => $this->context === null ? null : (object) $this->context, 'occurred_at' => $this->occurred_at->toISOString()];
    }
}
