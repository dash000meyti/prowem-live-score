<?php

namespace App\Actions;

use App\Enums\EventStatus;
use App\Enums\ReadinessStatus;
use App\Events\EventCareChanged;
use App\Exceptions\DomainRuleViolation;
use App\Models\Event;
use App\Models\ReadinessSnapshot;
use App\Models\User;
use App\Services\ActivityLogger;
use App\Services\ReadinessCalculator;
use Illuminate\Support\Facades\DB;

final class TransitionEvent
{
    public function __construct(private ActivityLogger $activity, private ReadinessCalculator $calculator) {}

    public function execute(Event $event, EventStatus $next, User $actor): Event
    {
        return DB::transaction(function () use ($event, $next, $actor) {
            $event = Event::query()->lockForUpdate()->findOrFail($event->id);
            $before = $event->status;
            if ($next === EventStatus::Live && $event->readinessChecks()->where('is_critical', true)->where('status', ReadinessStatus::Blocked->value)->exists()) {
                $blockers = $event->readinessChecks()->where('is_critical', true)->where('status', ReadinessStatus::Blocked->value)->get(['id', 'dimension', 'check_type', 'message', 'error_code']);
                throw new DomainRuleViolation('EVENT_NOT_READY', 'The event cannot be started because critical readiness blockers exist.', 409, ['blockers' => $blockers]);
            }
            if (! $before->canTransitionTo($next)) {
                throw new DomainRuleViolation('INVALID_EVENT_TRANSITION', "Cannot transition event from {$before->value} to {$next->value}.");
            }
            if ($next === EventStatus::Live) {
                $r = $this->calculator->calculate($event->readinessChecks()->get());
                ReadinessSnapshot::query()->create(['event_id' => $event->id, 'reason' => 'before_kickoff', 'status' => $r['status'], 'score' => $r['score'], 'critical_blockers_count' => $r['critical_blockers_count'], 'captured_at' => now()]);
            }
            $event->update(['status' => $next, 'completed_at' => $next === EventStatus::Completed ? now() : null]);
            $this->activity->log($event, 'event_status_changed', "Event changed {$before->value} → {$next->value}", $actor, 'event', $event->id);
            EventCareChanged::dispatch($event->id, 'event.status.changed', ['event_id' => $event->id, 'status' => $next->value]);

            return $event;
        });
    }
}
