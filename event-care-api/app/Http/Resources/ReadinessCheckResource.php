<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReadinessCheckResource extends JsonResource
{
    /** @return array{id:int,subject_type:string,subject_id:int|null,dimension:string,check_type:string,status:string,is_critical:bool,message:string|null,error_code:string|null,metadata:object|null,last_checked_at:string|null,resolved_at:string|null} */
    public function toArray(Request $request): array
    {
        return ['id' => (int) $this->id, 'subject_type' => $this->subject_type->value, 'subject_id' => $this->subject_id ? (int) $this->subject_id : null, 'dimension' => $this->dimension, 'check_type' => $this->check_type, 'status' => $this->status->value, 'is_critical' => (bool) $this->is_critical, 'message' => $this->message, 'error_code' => $this->error_code, 'metadata' => $this->metadata === null ? null : (object) $this->metadata, 'last_checked_at' => $this->last_checked_at?->toISOString(), 'resolved_at' => $this->resolved_at?->toISOString()];
    }
}
