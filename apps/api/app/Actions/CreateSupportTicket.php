<?php

namespace App\Actions;

use App\Enums\EventStatus;
use App\Enums\TicketPriority;
use App\Events\EventCareChanged;
use App\Models\Event;
use App\Models\SupportTicket;
use App\Models\User;
use App\Notifications\EventCareNotification;
use App\Services\ActivityLogger;
use App\Services\SlaCalculator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class CreateSupportTicket
{
    public function __construct(private SlaCalculator $sla, private ActivityLogger $activity) {}

    public function execute(Event $event, array $data, User $actor): SupportTicket
    {
        return DB::transaction(function () use ($event, $data, $actor) {
            if (! empty($data['idempotency_key']) && ($existing = SupportTicket::query()->where('event_id', $event->id)->where('idempotency_key', $data['idempotency_key'])->first())) {
                return $existing;
            }

            $requested = $data['requested_urgency'];
            $priority = match (true) {
                $event->status === EventStatus::Live && in_array($data['affected_service'] ?? null, ['live_score', 'streaming', 'graphics', 'platform'], true) && $requested === 'critical' => TicketPriority::P1,
                $requested === 'critical', $requested === 'high' => TicketPriority::P2,
                $requested === 'normal' => TicketPriority::P3,
                default => TicketPriority::P4
            };
            $ticket = SupportTicket::query()->create(['event_id' => $event->id, 'reference' => 'EC-'.now()->format('ymd').'-'.strtoupper(substr((string) Str::uuid(), 0, 6)), 'category' => $data['category'], 'affected_service' => $data['affected_service'] ?? null, 'fixture_id' => $data['fixture_id'] ?? null, 'venue_id' => $data['venue_id'] ?? null, 'idempotency_key' => $data['idempotency_key'] ?? null, 'priority' => $priority, 'status' => 'open', 'subject' => $data['subject'], 'description' => $data['description'], 'sla_due_at' => $this->sla->responseDeadline($priority, $event->account->plan, $event->status === EventStatus::Live)]);
            $this->activity->log($event, 'support_ticket_created', "Support request created: {$ticket->subject}", $actor, 'support_ticket', $ticket->id);
            $actor->notify(new EventCareNotification(['event_id' => $event->id, 'type' => 'ticket_created', 'title' => 'Support request created', 'body' => $ticket->subject]));
            EventCareChanged::dispatch($event->id, 'ticket.created', ['id' => $ticket->id, 'reference' => $ticket->reference, 'priority' => $priority->value]);

            return $ticket;
        });
    }
}
