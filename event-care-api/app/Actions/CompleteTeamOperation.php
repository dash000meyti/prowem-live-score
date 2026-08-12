<?php

namespace App\Actions;

use App\Enums\TeamOperation;
use App\Events\EventCareChanged;
use App\Models\Event;
use App\Models\Team;
use App\Models\TeamOperationState;
use App\Models\User;
use App\Notifications\EventCareNotification;
use App\Services\ActivityLogger;
use App\Services\EventReadinessService;
use App\Services\TeamReadinessProjector;
use Illuminate\Support\Facades\DB;

final class CompleteTeamOperation
{
    public function __construct(private TeamReadinessProjector $projector, private EventReadinessService $readiness, private ActivityLogger $activity) {}

    public function execute(Event $event, Team $team, TeamOperation $operation, User $actor): Team
    {
        return DB::transaction(function () use ($event, $team, $operation, $actor) {
            $team = Team::query()->where('event_id', $event->id)->lockForUpdate()->findOrFail($team->id);
            $state = TeamOperationState::query()->firstOrCreate(['event_id' => $event->id, 'team_id' => $team->id, 'operation' => $operation->value], ['completed_by' => $actor->id, 'completed_at' => now()]);
            $before = $team->readiness_status;
            $result = $this->projector->project($event, $team, $operation);
            if ($state->wasRecentlyCreated) {
                $this->activity->log($event, 'team_operation_completed', "{$operation->label()} completed for {$team->name}", $actor, 'team', $team->id, ['operation' => $operation->value]);
            }
            if ($before !== $result['status']) {
                $actor->notify(new EventCareNotification(['event_id' => $event->id, 'type' => 'team_readiness_changed', 'title' => 'Team readiness changed', 'body' => "{$team->name} is now {$result['status']->value}."]));
            }

            EventCareChanged::dispatch($event->id, 'team.readiness.changed', ['team_id' => $team->id, 'status' => $result['status']->value, 'score' => $result['score']]);
            EventCareChanged::dispatch($event->id, 'event.readiness.changed', $this->readiness->summaryPayload($event));

            return $team;
        });
    }
}
