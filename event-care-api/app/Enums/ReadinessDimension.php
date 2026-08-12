<?php

namespace App\Enums;

enum ReadinessDimension: string
{
    case Teams = 'teams';
    case Players = 'players';
    case Fixtures = 'fixtures';
    case Referees = 'referees';
    case Venues = 'venues';
    case Staff = 'staff';
    case LiveScore = 'live_score';
    case Streaming = 'streaming';
    case Graphics = 'graphics';

    public function label(): string
    {
        return ucwords(str_replace('_', ' ', $this->value));
    }
}
