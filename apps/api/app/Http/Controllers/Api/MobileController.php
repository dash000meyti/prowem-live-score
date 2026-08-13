<?php

namespace App\Http\Controllers\Api;

use App\Enums\ReadinessDimension;
use App\Enums\ReadinessStatus;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\EventIndexRequest;
use App\Http\Resources\EventListResource;
use App\Http\Resources\IncidentResource;
use App\Http\Resources\LiveControlResource;
use App\Http\Resources\ReadinessDimensionDetailResource;
use App\Http\Responses\ApiResponse;
use App\Models\Event;
use App\Models\ReadinessCheck;
use App\Services\EventReadinessService;
use App\Services\ReadinessCalculator;
use Dedoc\Scramble\Attributes\Response;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;

class MobileController extends Controller
{
    public function __construct(private EventReadinessService $readiness) {}

    #[Response(type: 'array{success: true, message: string|null, data: array{id:int,name:string,email:string,role:string,customer:array{id:int,name:string}|null}}')]
    public function me(): JsonResponse
    {
        $u = request()->user();

        return ApiResponse::success(['id' => (int) $u->id, 'name' => $u->name, 'email' => $u->email, 'role' => $u->role->value, 'customer' => $u->account?->only(['id', 'name'])], 'Current user retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: list<\App\Http\Resources\EventListResource>, meta: array{pagination: array{current_page:int,per_page:int,total:int,last_page:int,from:int|null,to:int|null}}, links: array{first:string,last:string,prev:string|null,next:string|null}}')]
    public function events(EventIndexRequest $request): JsonResponse
    {
        $u = $request->user();
        $q = $this->visibleEvents($u)->when($request->status, fn ($q, $v) => $q->where('status', $v))->when($request->boolean('needs_attention'), fn ($q) => $this->needsAttention($q))->when($request->search, fn ($q, $v) => $q->where(fn ($q) => $q->where('name', 'ilike', "%{$v}%")->orWhere('external_reference', 'ilike', "%{$v}%")))->when($request->from, fn ($q, $v) => $q->where('starts_at', '>=', $v))->when($request->to, fn ($q, $v) => $q->where('starts_at', '<=', $v))->with(['venues', 'readinessChecks'])->withCount(['teams', 'venues', 'incidents as open_incidents_count' => fn ($q) => $q->where('status', '!=', 'resolved'), 'incidents as critical_incidents_count' => fn ($q) => $q->where('status', '!=', 'resolved')->where('severity', 'critical'), 'tickets as open_tickets_count' => fn ($q) => $q->where('status', '!=', 'resolved')]);
        $p = $q->orderBy($request->input('sort', 'starts_at'), $request->input('direction', 'asc'))->paginate($request->perPage())->withQueryString();
        $p->getCollection()->each(function ($event) {
            $event->venue_summary = $event->venues->first()?->only(['id', 'name']);
            $event->readiness_summary = collect($this->readiness->summarize($event))->only(['status', 'score', 'critical_blockers_count', 'actions_required_count'])->all();
        });

        return ApiResponse::paginated($p, EventListResource::class, 'Events retrieved successfully.');
    }

    public function eventSummary(): JsonResponse
    {
        $query = $this->visibleEvents(request()->user());
        $statusCounts = (clone $query)->selectRaw('status, count(*) as aggregate')->groupBy('status')->pluck('aggregate', 'status');

        return ApiResponse::success(['all' => (clone $query)->count(), 'needs_attention' => $this->needsAttention(clone $query)->count(), 'preparing' => (int) ($statusCounts['preparing'] ?? 0), 'ready' => (int) ($statusCounts['ready'] ?? 0), 'live' => (int) ($statusCounts['live'] ?? 0), 'completed' => (int) ($statusCounts['completed'] ?? 0), 'cancelled' => (int) ($statusCounts['cancelled'] ?? 0)], 'Event summary retrieved successfully.');
    }

    private function visibleEvents($user): Builder
    {
        return Event::query()->when($user->role === UserRole::Organizer, fn ($q) => $q->where('account_id', $user->account_id));
    }

    private function needsAttention(Builder $query): Builder
    {
        return $query->where(function (Builder $query): void {
            $query->whereHas('readinessChecks', fn ($q) => $q->where('status', '!=', ReadinessStatus::Ready->value))->orWhereHas('incidents', fn ($q) => $q->where('status', '!=', 'resolved'))->orWhereHas('tickets', fn ($q) => $q->where('status', '!=', 'resolved'));
        });
    }

    #[Response(type: 'array{success:true,message:string|null,data:\App\Http\Resources\ReadinessDimensionDetailResource}')]
    public function dimension(Event $event, ReadinessDimension $dimension): JsonResponse
    {
        $this->authorize('view', $event);
        $checks = ReadinessCheck::query()->where('event_id', $event->id)->where('dimension', $dimension->value)->orderByRaw("case status when 'blocked' then 1 when 'warning' then 2 else 3 end")->get();
        $result = app(ReadinessCalculator::class)->calculate($checks);
        $summary = ['status' => $result['status']->value, 'score' => $result['score'], 'ready' => $checks->where('status', ReadinessStatus::Ready)->count(), 'total' => $checks->count(), 'actions_required' => $checks->whereIn('status', [ReadinessStatus::Warning, ReadinessStatus::Blocked])->count()];
        $items = $checks->map(fn ($check) => ['id' => (int) $check->id, 'label' => $check->metadata['label'] ?? ucwords(str_replace('_', ' ', $check->check_type)), 'status' => $check->status->value, 'message' => $check->message, 'action' => $check->metadata['action'] ?? null, 'subject' => ['type' => $check->subject_type->value, 'id' => $check->subject_id ? (int) $check->subject_id : null], 'metadata' => $check->metadata])->values()->all();

        return ApiResponse::resource(new ReadinessDimensionDetailResource(['dimension' => ['key' => $dimension->value, 'label' => $dimension->label()], 'summary' => $summary, 'items' => $items]), 'Readiness dimension retrieved successfully.');
    }

    #[Response(type: 'array{success:true,message:string|null,data:\App\Http\Resources\LiveControlResource}')]
    public function live(Event $event): JsonResponse
    {
        $this->authorize('view', $event);

        return ApiResponse::resource(new LiveControlResource(['event' => ['id' => (int) $event->id, 'status' => $event->status->value], 'progress' => ['completed' => $event->fixtures()->where('status', 'completed')->count(), 'total' => $event->fixtures()->count()], 'live_matches' => $event->fixtures()->where('status', 'live')->limit(10)->get()->toArray(), 'next_matches' => $event->fixtures()->where('status', 'scheduled')->orderBy('kickoff_at')->limit(10)->get()->toArray(), 'delayed_matches' => $event->fixtures()->where('delay_minutes', '>', 0)->limit(10)->get()->toArray(), 'operational_incidents' => IncidentResource::collection($event->incidents()->where('type', 'operational')->where('status', '!=', 'resolved')->limit(10)->get())->resolve(request()), 'system_status' => $this->readiness->summarize($event)]), 'Live Event Control retrieved successfully.');
    }
}
