<?php

namespace App\Enums;

enum IncidentType: string
{
    case Operational = 'operational';
    case Technical = 'technical';
}
