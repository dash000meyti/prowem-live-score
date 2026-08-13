<?php

namespace App\Models;

use App\Enums\ReadinessStatus;
use App\Enums\ReadinessSubjectType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReadinessCheck extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['status' => ReadinessStatus::class, 'subject_type' => ReadinessSubjectType::class, 'is_critical' => 'boolean', 'metadata' => 'array', 'last_checked_at' => 'immutable_datetime', 'resolved_at' => 'immutable_datetime'];
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }
}
