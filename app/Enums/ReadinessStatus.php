<?php

namespace App\Enums;

enum ReadinessStatus: string
{
    case Ready = 'ready';
    case Warning = 'warning';
    case Blocked = 'blocked';
}
