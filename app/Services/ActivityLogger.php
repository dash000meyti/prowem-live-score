<?php

namespace App\Services;

use App\Events\EventCareChanged;
use App\Models\Activity;
use App\Models\Event;
use App\Models\User;

final class ActivityLogger
{
    public function log(Event $event, string $type, string $description, ?User $actor = null, ?string $subjectType = null, ?int $subjectId = null, array $context = []): Activity
    {
        $activity = Activity::query()->create(['event_id' => $event->id, 'actor_id' => $actor?->id, 'type' => $type, 'subject_type' => $subjectType, 'subject_id' => $subjectId, 'description' => $description, 'context' => $context ?: null, 'occurred_at' => now()]);
        EventCareChanged::dispatch($event->id, 'activity.created', ['id' => $activity->id, 'type' => $type, 'description' => $description, 'occurred_at' => $activity->occurred_at->toISOString()]);

        return $activity;
    }
}
