<?php

namespace App\Http\Controllers\Api;

use App\Actions\TransitionEvent;
use App\Enums\EventStatus;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\ActivityIndexRequest;
use App\Http\Requests\TransitionEventRequest;
use App\Http\Resources\ActivityResource;
use App\Http\Resources\EventCareLookupsResource;
use App\Http\Resources\EventCareOverviewResource;
use App\Http\Resources\EventCareReportResource;
use App\Http\Resources\EventReadinessResource;
use App\Http\Resources\EventResource;
use App\Http\Resources\IncidentResource;
use App\Http\Resources\ReadinessCheckResource;
use App\Http\Resources\SupportTicketResource;
use App\Http\Resources\TeamReadinessResource;
use App\Http\Responses\ApiResponse;
use App\Models\Event;
use App\Models\Fixture;
use App\Models\Team;
use App\Models\User;
use App\Models\Venue;
use App\Services\EventReadinessService;
use App\Services\EventReportService;
use Dedoc\Scramble\Attributes\Response;
use Illuminate\Http\JsonResponse;

class EventCareController extends Controller
{
    public function __construct(private EventReadinessService $readiness, private EventReportService $report) {}

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\EventCareOverviewResource}')]
    public function overview(Event $event): JsonResponse
    {
        $this->authorize('view', $event);
        $readiness = $this->readiness->summarize($event);
        $eventData = (new EventResource($event))->resolve(request());
        $eventData['venue'] = $event->venues()->first()?->only(['id', 'name']);
        $eventData['team_count'] = $event->teams()->count();
        $eventData['field_count'] = $event->venues()->count();
        $data = ['event' => $eventData, 'readiness' => $readiness, 'readiness_dimensions' => $readiness['dimensions'], 'needs_attention' => ReadinessCheckResource::collection($event->readinessChecks()->whereIn('status', ['blocked', 'warning'])->orderByDesc('is_critical')->orderByRaw("case status when 'blocked' then 1 else 2 end")->limit(10)->get())->resolve(request()), 'open_critical_incidents' => IncidentResource::collection($event->incidents()->with('ticket')->where('status', '!=', 'resolved')->where('severity', 'critical')->latest('started_at')->limit(5)->get())->resolve(request()), 'open_tickets' => SupportTicketResource::collection($event->tickets()->with(['assignee', 'event'])->where('status', '!=', 'resolved')->orderBy('sla_due_at')->limit(5)->get())->resolve(request()), 'next_matches' => $event->fixtures()->with(['venue', 'homeTeam:id,name', 'awayTeam:id,name'])->where('kickoff_at', '>=', now())->orderBy('kickoff_at')->limit(5)->get()->map(fn ($f) => ['id' => (int) $f->id, 'number' => (int) $f->number, 'kickoff_at' => $f->kickoff_at->toISOString(), 'status' => $f->status, 'field' => $f->venue?->name, 'home_team' => $f->homeTeam?->only(['id', 'name']), 'away_team' => $f->awayTeam?->only(['id', 'name'])]), 'recent_activity' => ActivityResource::collection($event->activities()->with('actor')->latest('occurred_at')->limit(10)->get())->resolve(request())];

        return ApiResponse::resource(new EventCareOverviewResource($data), 'Event Care overview retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\EventCareLookupsResource}')]
    public function lookups(Event $event): JsonResponse
    {
        $this->authorize('view', $event);
        $teams = Team::query()->where('event_id', $event->id)->get(['id', 'name'])->keyBy('id');
        $venues = [];
        foreach (Venue::query()->where('event_id', $event->id)->orderBy('name')->get(['id', 'name']) as $venue) {
            $venues[] = ['id' => (int) $venue->id, 'name' => $venue->name];
        }
        $fixtures = [];
        foreach (Fixture::query()->where('event_id', $event->id)->orderBy('number')->get() as $fixture) {
            $home = $teams->get($fixture->home_team_id);
            $away = $teams->get($fixture->away_team_id);
            $kickoff = $fixture->getAttribute('kickoff_at');
            $fixtures[] = [
                'id' => (int) $fixture->id,
                'number' => (int) $fixture->number,
                'kickoff_at' => $kickoff instanceof \Carbon\CarbonInterface ? $kickoff->toISOString() : (string) $kickoff,
                'status' => $fixture->status,
                'venue_id' => $fixture->venue_id ? (int) $fixture->venue_id : null,
                'home_team' => $home instanceof Team ? ['id' => (int) $home->id, 'name' => $home->name] : null,
                'away_team' => $away instanceof Team ? ['id' => (int) $away->id, 'name' => $away->name] : null,
            ];
        }
        $user = request()->user();
        $staff = [];
        if ($user instanceof User && $user->can('support', $event)) {
            foreach (User::query()->whereIn('role', [UserRole::SupportAgent, UserRole::SupportLead, UserRole::Admin])->orderBy('name')->get() as $member) {
                $staff[] = ['id' => (int) $member->id, 'name' => $member->name, 'role' => (string) $member->getRawOriginal('role')];
            }
        }

        return ApiResponse::resource(new EventCareLookupsResource(['venues' => $venues, 'fixtures' => $fixtures, 'staff' => $staff]), 'Event lookups retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\EventReadinessResource}')]
    public function readiness(Event $event): JsonResponse
    {
        $this->authorize('view', $event);

        return ApiResponse::resource(new EventReadinessResource($this->readiness->summarize($event)), 'Event readiness retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: list<\App\Http\Resources\TeamReadinessResource>, meta: array{pagination: array{current_page:int,per_page:int,total:int,last_page:int,from:int|null,to:int|null}}, links: array{first:string,last:string,prev:string|null,next:string|null}}')]
    public function teams(Event $event): JsonResponse
    {
        $this->authorize('view', $event);
        $per = min(max((int) request('per_page', 20), 1), 100);
        $p = $event->teams()->when(request('status'), fn ($q, $v) => $q->where('readiness_status', $v))->when(request('search'), fn ($q, $v) => $q->where('name', 'ilike', '%'.str_replace(['%', '_'], ['\\%', '\\_'], $v).'%'))->orderBy('name')->paginate($per)->withQueryString();
        $ids = $p->getCollection()->pluck('id');
        $checks = $event->readinessChecks()->where('subject_type', 'team')->whereIn('subject_id', $ids)->get()->groupBy('subject_id');
        $fixtures = $event->fixtures()->with('venue')->where(fn ($q) => $q->whereIn('home_team_id', $ids)->orWhereIn('away_team_id', $ids))->orderBy('kickoff_at')->get();
        $p->getCollection()->each(function ($team) use ($checks, $fixtures) {
            $team->checks = $checks->get($team->id, collect());
            $f = $fixtures->first(fn ($fixture) => $fixture->home_team_id === $team->id || $fixture->away_team_id === $team->id);
            $team->first_match = $f ? ['id' => $f->id, 'kickoff_at' => $f->kickoff_at->toISOString(), 'field' => $f->venue?->name] : null;
        });

        return ApiResponse::paginated($p, TeamReadinessResource::class, 'Team readiness retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\TeamReadinessResource}')]
    public function team(Event $event, Team $team): JsonResponse
    {
        $this->authorize('view', $event);
        abort_unless($team->event_id === $event->id, 404);
        $team->checks = $event->readinessChecks()->where('subject_type', 'team')->where('subject_id', $team->id)->orderBy('check_type')->get();
        $fixture = $event->fixtures()->with('venue')->where(fn ($q) => $q->where('home_team_id', $team->id)->orWhere('away_team_id', $team->id))->orderBy('kickoff_at')->first();
        $team->first_match = $fixture ? ['id' => $fixture->id, 'kickoff_at' => $fixture->kickoff_at->toISOString(), 'field' => $fixture->venue?->name] : null;

        return ApiResponse::resource(new TeamReadinessResource($team), 'Team readiness retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\EventResource}')]
    public function transition(Event $event, TransitionEventRequest $request, TransitionEvent $action): JsonResponse
    {
        $this->authorize('manage', $event);

        return ApiResponse::resource(new EventResource($action->execute($event, EventStatus::from($request->validated('status')), $request->user())), 'Event status updated successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: list<\App\Http\Resources\ActivityResource>, meta: array{pagination: array{current_page:int,per_page:int,total:int,last_page:int,from:int|null,to:int|null}}, links: array{first:string,last:string,prev:string|null,next:string|null}}')]
    public function activity(Event $event, ActivityIndexRequest $request): JsonResponse
    {
        $this->authorize('view', $event);
        $q = $event->activities()->with('actor')->when($request->type, fn ($q, $v) => $q->where('type', $v))->when($request->actor_id, fn ($q, $v) => $q->where('actor_id', $v))->when($request->from, fn ($q, $v) => $q->where('occurred_at', '>=', $v))->when($request->to, fn ($q, $v) => $q->where('occurred_at', '<=', $v))->latest('occurred_at');

        return ApiResponse::paginated($q->paginate($request->perPage())->withQueryString(), ActivityResource::class, 'Activity retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\EventCareReportResource}')]
    public function report(Event $event): JsonResponse
    {
        $this->authorize('view', $event);

        return ApiResponse::resource(new EventCareReportResource($this->report->build($event)), 'Event Care report retrieved successfully.');
    }
}
