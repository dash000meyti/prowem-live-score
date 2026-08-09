<?php

namespace App\Enums;

enum GameStatus: string
{
    case Scheduled = 'scheduled';
    case InPlay = 'in_play';
    case Finished = 'finished';
}
