<?php

namespace App\Actions;

use App\Enums\ReadinessStatus;
use App\Enums\ReadinessSubjectType;
use App\Events\EventCareChanged;
use App\Models\ReadinessCheck;
use App\Models\Team;
use App\Models\User;
use App\Services\ActivityLogger;
use App\Services\ReadinessCalculator;
use Illuminate\Support\Facades\DB;

final class UpdateReadinessCheck
{
    public function __construct(private ReadinessCalculator $calculator, private ActivityLogger $activity) {}

    public function execute(ReadinessCheck $check, ReadinessStatus $status, ?string $message, string $reason, User $actor): ReadinessCheck
    {
        return DB::transaction(function () use ($check, $status, $message, $reason, $actor) {
            $locked = ReadinessCheck::query()->lockForUpdate()->findOrFail($check->id);
            $before = $locked->status;
            $locked->update(['status' => $status, 'message' => $message, 'last_checked_at' => now(), 'resolved_at' => $status === ReadinessStatus::Ready ? now() : null]);
            $event = $locked->event;
            if ($locked->subject_type === ReadinessSubjectType::Team && $locked->subject_id) {
                $checks = ReadinessCheck::query()->where('event_id', $event->id)->where('subject_type', 'team')->where('subject_id', $locked->subject_id)->get();
                $result = $this->calculator->calculate($checks);
                $team = Team::query()->lockForUpdate()->findOrFail($locked->subject_id);
                $teamBefore = $team->readiness_status;
                $team->update(['readiness_status' => $result['status'], 'readiness_score' => $result['score']]);
                if ($teamBefore !== $result['status']) {
                    $this->activity->log($event, 'team_readiness_changed', "{$team->name} changed {$teamBefore->value} → {$result['status']->value}", $actor, 'team', $team->id);
                }EventCareChanged::dispatch($event->id, 'team.readiness.changed', ['team_id' => $team->id, 'status' => $result['status']->value, 'score' => $result['score']]);
            }
            $this->activity->log($event, 'readiness_check_overridden', "{$locked->check_type} manually overridden", $actor, 'readiness_check', $locked->id, ['before' => $before->value, 'after' => $status->value, 'reason' => $reason]);
            EventCareChanged::dispatch($event->id, 'event.readiness.changed', ['event_id' => $event->id]);

            return $locked->fresh();
        });
    }
}
