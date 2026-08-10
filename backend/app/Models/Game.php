<?php

namespace App\Models;

use App\Enums\GameStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int $home_team_id
 * @property int $away_team_id
 * @property int $round_number
 * @property int|null $home_score
 * @property int|null $away_score
 * @property GameStatus $status
 * @property Carbon|null $kickoff_at
 */
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
            'home_team_id' => 'integer',
            'away_team_id' => 'integer',
            'round_number' => 'integer',
            'home_score' => 'integer',
            'away_score' => 'integer',
            'status' => GameStatus::class,
            'kickoff_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Team, $this>
     */
    public function homeTeam(): BelongsTo
    {
        return $this->belongsTo(
            Team::class,
            'home_team_id'
        );
    }

    /**
     * @return BelongsTo<Team, $this>
     */
    public function awayTeam(): BelongsTo
    {
        return $this->belongsTo(
            Team::class,
            'away_team_id'
        );
    }
}
