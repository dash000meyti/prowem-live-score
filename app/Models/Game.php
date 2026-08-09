<?php

namespace App\Models;

use App\Enums\GameStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Game extends Model
{
    protected $table = 'matches';

    protected $fillable = [
        'home_team_id',
        'away_team_id',
        'round_number',
        'home_score',
        'away_score',
        'status',
        'kickoff_at',
    ];

    protected function casts(): array
    {
        return [
            'round_number' => 'integer',
            'status' => GameStatus::class,
            'kickoff_at' => 'datetime',
        ];
    }

    public function homeTeam(): BelongsTo
    {
        return $this->belongsTo(Team::class, 'home_team_id');

    }

    public function awayTeam(): BelongsTo
    {
        return $this->belongsTo(Team::class, 'away_team_id');
    }
}
