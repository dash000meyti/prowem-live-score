<?php

namespace App\Enums;

enum UserRole: string
{
    case Organizer = 'organizer';
    case SupportAgent = 'support_agent';
    case SupportLead = 'support_lead';
    case Admin = 'admin';
}
