<?php

namespace App\Http\Controllers\Api;

use App\Actions\CompleteTeamOperation;
use App\Enums\TeamOperation;
use App\Http\Controllers\Controller;
use App\Http\Resources\TeamReadinessResource;
use App\Http\Responses\ApiResponse;
use App\Models\Event;
use App\Models\ReadinessCheck;
use App\Models\Team;
use App\Services\EventReadinessService;
use Dedoc\Scramble\Attributes\Response;
use Illuminate\Http\JsonResponse;

class TeamOperationController extends Controller
{
    public function __construct(private EventReadinessService $readiness) {}

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\TeamReadinessResource}')]
    public function __invoke(Event $event, Team $team, TeamOperation $operation, CompleteTeamOperation $action): JsonResponse
    {
        $this->authorize('manage', $event);
        abort_unless($team->event_id === $event->id, 404);
        $team = $action->execute($event, $team, $operation, request()->user());
        $team->checks = ReadinessCheck::query()->where('event_id', $event->id)->where('subject_type', 'team')->where('subject_id', $team->id)->get();
        $team->first_match = $event->fixtures()->where(fn ($q) => $q->where('home_team_id', $team->id)->orWhere('away_team_id', $team->id))->orderBy('kickoff_at')->first()?->only(['id', 'kickoff_at', 'venue_id']);

        return ApiResponse::resource(new TeamReadinessResource($team), 'Team operation completed successfully.');
    }
}
