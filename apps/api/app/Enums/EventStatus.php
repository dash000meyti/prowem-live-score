<?php

namespace App\Enums;

enum EventStatus: string
{
    case Preparing = 'preparing';
    case Ready = 'ready';
    case Live = 'live';
    case Completed = 'completed';
    case Cancelled = 'cancelled';

    public function canTransitionTo(self $next): bool
    {
        return match ($this) {
            self::Preparing => in_array($next, [self::Ready, self::Cancelled], true),
            self::Ready => in_array($next, [self::Preparing, self::Live, self::Cancelled], true),
            self::Live => in_array($next, [self::Completed, self::Cancelled], true),
            self::Completed, self::Cancelled => false,
        };
    }
}
