<?php

namespace App\Http\Controllers\Api;

use App\Actions\CreateSupportTicket;
use App\Actions\UpdateTicket;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTicketRequest;
use App\Http\Requests\TicketIndexRequest;
use App\Http\Requests\UpdateTicketRequest;
use App\Http\Resources\SupportTicketResource;
use App\Http\Responses\ApiResponse;
use App\Models\Event;
use App\Models\SupportTicket;
use Dedoc\Scramble\Attributes\Response;
use Illuminate\Http\JsonResponse;

class TicketController extends Controller
{
    #[Response(type: 'array{success: true, message: string|null, data: list<\App\Http\Resources\SupportTicketResource>, meta: array{pagination: array{current_page:int,per_page:int,total:int,last_page:int,from:int|null,to:int|null}}, links: array{first:string,last:string,prev:string|null,next:string|null}}')]
    public function index(Event $event, TicketIndexRequest $request): JsonResponse
    {
        $this->authorize('view', $event);
        $q = $event->tickets()->with(['assignee', 'incident', 'event', 'venue', 'fixture.venue'])->when($request->status, fn ($q, $v) => $q->where('status', $v))->when($request->priority, fn ($q, $v) => $q->where('priority', $v))->when($request->assignee_id, fn ($q, $v) => $q->where('assignee_id', $v));

        return ApiResponse::paginated($q->orderBy($request->input('sort', 'created_at'), $request->input('direction', 'desc'))->paginate($request->perPage())->withQueryString(), SupportTicketResource::class, 'Tickets retrieved successfully.');
    }

    #[Response(type: 'array{success:true,message:string|null,data:array{event:array{id:int,name:string,status:string},critical:\App\Http\Resources\SupportTicketResource|null,open:list<\App\Http\Resources\SupportTicketResource>,resolved:list<\App\Http\Resources\SupportTicketResource>,counts:array{open:int,resolved:int}}}')]
    public function home(Event $event): JsonResponse
    {
        $this->authorize('view', $event);
        $base = $event->tickets()->with(['assignee', 'incident', 'venue', 'fixture.venue']);
        $open = (clone $base)->where('status', '!=', 'resolved')->orderByRaw("case priority when 'p1' then 1 when 'p2' then 2 when 'p3' then 3 else 4 end")->orderBy('sla_due_at')->limit(10)->get();
        $resolved = (clone $base)->where('status', 'resolved')->latest('resolved_at')->limit(10)->get();
        $critical = $open->first(fn (SupportTicket $ticket) => $ticket->getRawOriginal('priority') === 'p1');

        return ApiResponse::success([
            'event' => ['id' => (int) $event->id, 'name' => $event->name, 'status' => $event->status->value],
            'critical' => $critical ? (new SupportTicketResource($critical))->resolve(request()) : null,
            'open' => SupportTicketResource::collection($open->reject(fn (SupportTicket $ticket) => $critical && $ticket->id === $critical->id)->values())->resolve(request()),
            'resolved' => SupportTicketResource::collection($resolved)->resolve(request()),
            'counts' => ['open' => $event->tickets()->where('status', '!=', 'resolved')->count(), 'resolved' => $event->tickets()->where('status', 'resolved')->count()],
        ], 'Support home retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\SupportTicketResource}')]
    public function show(SupportTicket $ticket): JsonResponse
    {
        $this->authorize('view', $ticket->event);

        return ApiResponse::resource(new SupportTicketResource($ticket->load(['assignee', 'incident', 'event', 'venue', 'fixture.venue'])), 'Ticket retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\SupportTicketResource}')]
    public function update(SupportTicket $ticket, UpdateTicketRequest $request, UpdateTicket $action): JsonResponse
    {
        $this->authorize('support', $ticket->event);

        return ApiResponse::resource(new SupportTicketResource($action->execute($ticket, $request->validated(), $request->user())), 'Ticket updated successfully.');
    }

    /** Create an Organizer support request with server-calculated priority and SLA. */
    #[Response(status: 201, type: 'array{success: true, message: string|null, data: \App\Http\Resources\SupportTicketResource}')]
    public function store(Event $event, StoreTicketRequest $request, CreateSupportTicket $action): JsonResponse
    {
        $this->authorize('view', $event);

        return ApiResponse::resource(new SupportTicketResource($action->execute($event, $request->validated(), $request->user())), 'Support ticket created successfully.', 201);
    }
}
