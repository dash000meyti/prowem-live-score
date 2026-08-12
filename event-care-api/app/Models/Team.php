<?php

namespace App\Models;

use App\Enums\ReadinessStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Team extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['readiness_status' => ReadinessStatus::class];
    }

    public function event(): BelongsTo
    {
        return $this->belongsTo(Event::class);
    }
}
