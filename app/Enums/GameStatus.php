<?php

namespace App\Enums;

enum GameStatus: string
{
    case Scheduled = 'scheduled';
    case InPlay = 'in_play';
    case Finished = 'finished';

    public function canTransitionTo(self $next): bool
    {
        return match ($this) {
            self::Scheduled, self::InPlay => in_array(
                $next,
                [
                    self::InPlay,
                    self::Finished,
                ],
                true
            ),

            self::Finished => $next === self::Finished,
        };
    }
}
