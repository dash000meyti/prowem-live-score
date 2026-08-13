<?php

namespace App\Enums;

enum ReadinessSubjectType: string
{
    case Event = 'event';
    case Team = 'team';
    case Venue = 'venue';
    case Referee = 'referee';
    case Service = 'service';
}
