<?php

namespace App\Policies;

use App\Enums\UserRole;
use App\Models\Event;
use App\Models\User;

class EventPolicy
{
    public function view(User $user, Event $event): bool
    {
        return in_array($user->role, [UserRole::SupportAgent, UserRole::SupportLead, UserRole::Admin], true) || $user->account_id === $event->account_id;
    }

    public function manage(User $user, Event $event): bool
    {
        return $this->view($user, $event) && in_array($user->role, [UserRole::Organizer, UserRole::SupportLead, UserRole::Admin], true);
    }

    public function support(User $user, Event $event): bool
    {
        return $this->view($user, $event) && in_array($user->role, [UserRole::SupportAgent, UserRole::SupportLead, UserRole::Admin], true);
    }
}
