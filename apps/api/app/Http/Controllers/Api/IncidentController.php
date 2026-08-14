<?php

namespace App\Http\Controllers\Api;

use App\Actions\CreateIncident;
use App\Actions\UpdateIncident;
use App\Enums\IncidentType;
use App\Http\Controllers\Controller;
use App\Http\Requests\IncidentIndexRequest;
use App\Http\Requests\StoreIncidentRequest;
use App\Http\Requests\UpdateIncidentRequest;
use App\Http\Resources\IncidentResource;
use App\Http\Responses\ApiResponse;
use App\Models\Event;
use App\Models\Incident;
use Dedoc\Scramble\Attributes\Response;
use Illuminate\Http\JsonResponse;

class IncidentController extends Controller
{
    #[Response(type: 'array{success: true, message: string|null, data: list<\App\Http\Resources\IncidentResource>, meta: array{pagination: array{current_page:int,per_page:int,total:int,last_page:int,from:int|null,to:int|null}}, links: array{first:string,last:string,prev:string|null,next:string|null}}')]
    public function index(Event $event, IncidentIndexRequest $request): JsonResponse
    {
        $this->authorize('view', $event);
        $q = $event->incidents()->with(['fixture', 'venue', 'ticket.assignee', 'ticket.venue', 'ticket.fixture.venue'])->when($request->status, fn ($q, $v) => $q->where('status', $v))->when($request->type, fn ($q, $v) => $q->where('type', $v))->when($request->category, fn ($q, $v) => $q->where('category', $v))->when($request->severity, fn ($q, $v) => $q->where('severity', $v))->when($request->from, fn ($q, $v) => $q->where('started_at', '>=', $v))->when($request->to, fn ($q, $v) => $q->where('started_at', '<=', $v));
        $sort = $request->input('sort', 'started_at');
        $direction = $request->input('direction', 'desc');

        return ApiResponse::paginated($q->orderBy($sort, $direction)->paginate($request->perPage())->withQueryString(), IncidentResource::class, 'Incidents retrieved successfully.');
    }

    #[Response(status: 201, type: 'array{success: true, message: string|null, data: \App\Http\Resources\IncidentResource}')]
    public function store(Event $event, StoreIncidentRequest $request, CreateIncident $action): JsonResponse
    {
        $ability = $request->validated('type') === IncidentType::Technical->value ? 'view' : 'manage';
        $this->authorize($ability, $event);
        $incident = $action->execute($event, $request->validated(), $request->user());

        return ApiResponse::resource(new IncidentResource($incident), 'Incident created successfully.', 201);
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\IncidentResource}')]
    public function show(Incident $incident): JsonResponse
    {
        $this->authorize('view', $incident->event);

        return ApiResponse::resource(new IncidentResource($incident->load(['fixture', 'venue', 'ticket.assignee', 'ticket.venue', 'ticket.fixture.venue'])), 'Incident retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\IncidentResource}')]
    public function update(Incident $incident, UpdateIncidentRequest $request, UpdateIncident $action): JsonResponse
    {
        $this->authorize($incident->type === IncidentType::Technical ? 'support' : 'manage', $incident->event);

        return ApiResponse::resource(new IncidentResource($action->execute($incident, $request->validated(), $request->user())), 'Incident updated successfully.');
    }
}
