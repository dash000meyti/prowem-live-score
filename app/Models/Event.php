<?php

namespace App\Models;

use App\Enums\EventStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Event extends Model
{
    protected $guarded = [];

    protected function casts(): array
    {
        return ['status' => EventStatus::class, 'starts_at' => 'immutable_datetime', 'ends_at' => 'immutable_datetime', 'completed_at' => 'immutable_datetime'];
    }

    public function account(): BelongsTo
    {
        return $this->belongsTo(Account::class);
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class)->withPivot('role');
    }

    public function teams(): HasMany
    {
        return $this->hasMany(Team::class);
    }

    public function fixtures(): HasMany
    {
        return $this->hasMany(Fixture::class);
    }

    /** @return HasMany<Venue, $this> */
    public function venues(): HasMany
    {
        return $this->hasMany(Venue::class);
    }

    public function readinessChecks(): HasMany
    {
        return $this->hasMany(ReadinessCheck::class);
    }

    public function incidents(): HasMany
    {
        return $this->hasMany(Incident::class);
    }

    public function tickets(): HasMany
    {
        return $this->hasMany(SupportTicket::class);
    }

    public function activities(): HasMany
    {
        return $this->hasMany(Activity::class);
    }
}
