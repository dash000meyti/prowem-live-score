<?php

use App\Enums\UserRole;
use App\Models\Event;
use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('events.{eventId}', function (User $user, int $eventId): bool {
    $event = Event::query()->find($eventId);

    return $event !== null && (in_array($user->role, [UserRole::SupportAgent, UserRole::SupportLead, UserRole::Admin], true) || $user->account_id === $event->account_id);
});
Broadcast::channel('App.Models.User.{id}', fn (User $user, int $id): bool => $user->id === $id);
