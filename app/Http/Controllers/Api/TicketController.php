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
        $q = $event->tickets()->with('assignee')->when($request->status, fn ($q, $v) => $q->where('status', $v))->when($request->priority, fn ($q, $v) => $q->where('priority', $v))->when($request->assignee_id, fn ($q, $v) => $q->where('assignee_id', $v));

        return ApiResponse::paginated($q->orderBy($request->input('sort', 'created_at'), $request->input('direction', 'desc'))->paginate($request->perPage())->withQueryString(), SupportTicketResource::class, 'Tickets retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\SupportTicketResource}')]
    public function show(SupportTicket $ticket): JsonResponse
    {
        $this->authorize('view', $ticket->event);

        return ApiResponse::resource(new SupportTicketResource($ticket->load('assignee')), 'Ticket retrieved successfully.');
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
