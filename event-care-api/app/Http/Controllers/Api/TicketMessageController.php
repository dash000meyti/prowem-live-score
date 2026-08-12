<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Events\EventCareChanged;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTicketMessageRequest;
use App\Http\Resources\TicketMessageResource;
use App\Http\Responses\ApiResponse;
use App\Models\SupportTicket;
use App\Models\TicketMessage;
use App\Notifications\EventCareNotification;
use App\Services\ActivityLogger;
use Dedoc\Scramble\Attributes\Response;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TicketMessageController extends Controller
{
    #[Response(type: 'array{success: true, message: string|null, data: list<\App\Http\Resources\TicketMessageResource>, meta: array{pagination: array{current_page:int,per_page:int,total:int,last_page:int,from:int|null,to:int|null}}, links: array{first:string,last:string,prev:string|null,next:string|null}}')]
    public function index(SupportTicket $ticket, Request $request): JsonResponse
    {
        $this->authorize('view', $ticket->event);
        $request->validate(['page' => ['sometimes', 'integer', 'min:1'], 'per_page' => ['sometimes', 'integer', 'min:1', 'max:100']]);
        $q = $ticket->messages()->with('author')->when($request->user()->role === UserRole::Organizer, fn ($q) => $q->where('visibility', 'customer'))->oldest();
        $per = min(max((int) $request->input('per_page', 20), 1), 100);

        return ApiResponse::paginated($q->paginate($per)->withQueryString(), TicketMessageResource::class, 'Ticket messages retrieved successfully.');
    }

    #[Response(status: 201, type: 'array{success: true, message: string|null, data: \App\Http\Resources\TicketMessageResource}')]
    public function store(SupportTicket $ticket, StoreTicketMessageRequest $request, ActivityLogger $activity): JsonResponse
    {
        $this->authorize('view', $ticket->event);
        $visibility = $request->input('visibility', 'customer');
        if ($request->user()->role === UserRole::Organizer) {
            $visibility = 'customer';
        }$key = $request->input('idempotency_key');
        $message = $key ? TicketMessage::query()->firstOrCreate(['ticket_id' => $ticket->id, 'idempotency_key' => $key], ['author_id' => $request->user()->id, 'visibility' => $visibility, 'body' => $request->validated('body')]) : TicketMessage::query()->create(['ticket_id' => $ticket->id, 'author_id' => $request->user()->id, 'visibility' => $visibility, 'body' => $request->validated('body')]);
        $activity->log($ticket->event, 'ticket_message_created', 'New support conversation message.', $request->user(), 'support_ticket', $ticket->id);
        if ($visibility === 'customer') {
            EventCareChanged::dispatch($ticket->event_id, 'ticket.message.created', ['ticket_id' => $ticket->id, 'message_id' => $message->id]);
            foreach ($ticket->event->users as $user) {
                $user->notify(new EventCareNotification(['event_id' => $ticket->event_id, 'type' => 'support_replied', 'title' => 'Support conversation updated', 'body' => $ticket->subject]));
            }
        }

        return ApiResponse::resource(new TicketMessageResource($message->load('author')), 'Ticket message created successfully.', 201);
    }
}
