<?php

namespace App\Services;

use App\Enums\ReadinessStatus;
use App\Enums\ReadinessSubjectType;
use App\Enums\TeamOperation;
use App\Models\Event;
use App\Models\ReadinessCheck;
use App\Models\Team;
use App\Models\TeamOperationState;

final class TeamReadinessProjector
{
    public function __construct(private ReadinessCalculator $calculator) {}

    public function project(Event $event, Team $team, TeamOperation $operation): array
    {
        $completed = TeamOperationState::query()->where('event_id', $event->id)->where('team_id', $team->id)->where('operation', $operation->value)->exists();
        $check = ReadinessCheck::query()->where('event_id', $event->id)->where('subject_type', ReadinessSubjectType::Team->value)->where('subject_id', $team->id)->where('check_type', $operation->checkType())->lockForUpdate()->firstOrFail();
        $check->update(['status' => $completed ? ReadinessStatus::Ready : $check->status, 'message' => $completed ? $operation->label().' completed.' : $check->message, 'last_checked_at' => now(), 'resolved_at' => $completed ? now() : null]);
        $result = $this->calculator->calculate(ReadinessCheck::query()->where('event_id', $event->id)->where('subject_type', ReadinessSubjectType::Team->value)->where('subject_id', $team->id)->get());
        $team->update(['readiness_status' => $result['status'], 'readiness_score' => $result['score']]);

        return $result;
    }
}
