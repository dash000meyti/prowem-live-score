<?php

namespace App\Actions;

use App\Enums\TicketStatus;
use App\Events\EventCareChanged;
use App\Exceptions\DomainRuleViolation;
use App\Models\SupportTicket;
use App\Models\User;
use App\Services\ActivityLogger;
use Illuminate\Support\Facades\DB;

final class UpdateTicket
{
    public function __construct(private ActivityLogger $activity) {}

    public function execute(SupportTicket $ticket, array $data, User $actor): SupportTicket
    {
        return DB::transaction(function () use ($ticket, $data, $actor) {
            $ticket = SupportTicket::query()->lockForUpdate()->findOrFail($ticket->id);
            $beforeStatus = $ticket->status;
            $beforePriority = $ticket->priority;
            $beforeAssigneeId = $ticket->assignee_id;
            $updates = collect($data)->only(['priority', 'status', 'assignee_id', 'resolution', 'resolution_code', 'customer_note', 'internal_note'])->all();
            if (isset($data['status'])) {
                $next = TicketStatus::from($data['status']);
                $allowed = match ($ticket->status) {
                    TicketStatus::Open => [TicketStatus::InProgress, TicketStatus::Waiting, TicketStatus::Resolved],TicketStatus::InProgress => [TicketStatus::Waiting, TicketStatus::Resolved],TicketStatus::Waiting => [TicketStatus::InProgress, TicketStatus::Resolved],TicketStatus::Resolved => [TicketStatus::Reopened],TicketStatus::Reopened => [TicketStatus::InProgress, TicketStatus::Resolved]
                };
                if (! in_array($next, $allowed, true)) {
                    throw new DomainRuleViolation('INVALID_TICKET_TRANSITION', 'The requested ticket transition is invalid.');
                }if ($next === TicketStatus::Resolved && blank($data['resolution'] ?? null)) {
                    throw new DomainRuleViolation('RESOLUTION_REQUIRED', 'A resolution is required to resolve a ticket.', 422);
                }if ($next === TicketStatus::InProgress && $ticket->first_response_at === null) {
                    $updates['first_response_at'] = now();
                }$updates['resolved_at'] = $next === TicketStatus::Resolved ? now() : null;
            }$ticket->update($updates);
            if ($ticket->priority !== $beforePriority) {
                $this->activity->log($ticket->event, 'ticket_priority_changed', "Ticket priority changed {$beforePriority->value} → {$ticket->priority->value}", $actor, 'support_ticket', $ticket->id);
            }if ($ticket->assignee_id !== $beforeAssigneeId) {
                $this->activity->log($ticket->event, 'ticket_assignment_changed', 'Ticket support owner updated', $actor, 'support_ticket', $ticket->id);
            }if ($ticket->status !== $beforeStatus) {
                $this->activity->log($ticket->event, 'ticket_'.$ticket->status->value, "Ticket changed {$beforeStatus->value} → {$ticket->status->value}", $actor, 'support_ticket', $ticket->id);
            }EventCareChanged::dispatch($ticket->event_id, $ticket->status === TicketStatus::Resolved ? 'ticket.resolved' : 'ticket.updated', ['id' => $ticket->id, 'status' => $ticket->status->value, 'priority' => $ticket->priority->value]);

            return $ticket->fresh(['incident', 'assignee']);
        });
    }
}
