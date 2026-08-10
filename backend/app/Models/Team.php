<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @property int $id
 * @property string $name
 * @property string|null $logo
 */
class Team extends Model
{
    protected $fillable = [
        'name',
        'logo',
    ];

    /**
     * @return HasMany<Game, $this>
     */
    public function homeGames(): HasMany
    {
        return $this->hasMany(
            Game::class,
            'home_team_id'
        );
    }

    /**
     * @return HasMany<Game, $this>
     */
    public function awayGames(): HasMany
    {
        return $this->hasMany(
            Game::class,
            'away_team_id'
        );
    }
}
