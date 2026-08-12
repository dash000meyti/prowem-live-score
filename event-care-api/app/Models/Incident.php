<?php

namespace App\Models;

use App\Enums\IncidentSeverity;
use App\Enums\IncidentStatus;
use App\Enums\IncidentType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Incident extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['type' => IncidentType::class, 'severity' => IncidentSeverity::class, 'status' => IncidentStatus::class, 'metadata' => 'array', 'started_at' => 'immutable_datetime', 'acknowledged_at' => 'immutable_datetime', 'resolved_at' => 'immutable_datetime'];
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }

    public function ticket(): HasOne
    {
        return $this->hasOne(SupportTicket::class);
    }
}
