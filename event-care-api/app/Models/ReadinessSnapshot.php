<?php

namespace App\Models;

use App\Enums\ReadinessStatus;
use Illuminate\Database\Eloquent\Model;

class ReadinessSnapshot extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['status' => ReadinessStatus::class, 'captured_at' => 'immutable_datetime'];
    }
}
