<?php

namespace App\Actions;

use App\Enums\EventStatus;
use App\Enums\IncidentSeverity;
use App\Enums\IncidentStatus;
use App\Enums\IncidentType;
use App\Enums\TicketPriority;
use App\Events\EventCareChanged;
use App\Exceptions\DomainRuleViolation;
use App\Models\Event;
use App\Models\Incident;
use App\Models\SupportTicket;
use App\Models\User;
use App\Notifications\EventCareNotification;
use App\Services\ActivityLogger;
use App\Services\SlaCalculator;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

final class CreateIncident
{
    public function __construct(private SlaCalculator $sla, private ActivityLogger $activity) {}

    public function execute(Event $event, array $data, User $actor): Incident
    {
        try {
            return DB::transaction(function () use ($event, $data, $actor) {
                if (isset($data['fixture_id']) && ! $event->fixtures()->whereKey($data['fixture_id'])->exists()) {
                    throw new DomainRuleViolation('FIXTURE_NOT_IN_EVENT', 'The fixture does not belong to this event.', 422);
                }
                if (isset($data['venue_id']) && ! $event->venues()->whereKey($data['venue_id'])->exists()) {
                    throw new DomainRuleViolation('VENUE_NOT_IN_EVENT', 'The venue does not belong to this event.', 422);
                }
                $type = IncidentType::from($data['type']);
                $severity = IncidentSeverity::from($data['severity']);
                $correlation = $data['correlation_key'] ?? ($type === IncidentType::Technical ? $data['category'].':'.($data['venue_id'] ?? 'event') : null);
                if ($correlation && Incident::query()->where('event_id', $event->id)->where('correlation_key', $correlation)->where('status', '!=', 'resolved')->exists()) {
                    throw new DomainRuleViolation('INCIDENT_ALREADY_OPEN', 'An active incident already exists for this problem.');
                }
                $incident = Incident::query()->create([...$data, 'event_id' => $event->id, 'created_by' => $actor->id, 'status' => IncidentStatus::Open, 'started_at' => $data['started_at'] ?? now(), 'correlation_key' => $correlation]);
                $this->activity->log($event, 'incident_created', "Incident created: {$incident->title}", $actor, 'incident', $incident->id);
                $autoEscalate = $type === IncidentType::Technical && $event->status === EventStatus::Live;
                $ticket = null;
                if ($autoEscalate) {
                    $priority = $severity === IncidentSeverity::Critical || $event->status === EventStatus::Live ? TicketPriority::P1 : TicketPriority::P2;
                    $ticket = SupportTicket::query()->create(['event_id' => $event->id, 'incident_id' => $incident->id, 'priority' => $priority, 'status' => 'open', 'subject' => $incident->title, 'description' => $incident->description, 'sla_due_at' => $this->sla->responseDeadline($priority, $event->account->plan, true)]);
                    $this->activity->log($event, 'support_ticket_created', strtoupper($priority->value)." ticket created: {$ticket->subject}", $actor, 'support_ticket', $ticket->id);
                }
                EventCareChanged::dispatch($event->id, 'incident.created', ['id' => $incident->id, 'type' => $type->value, 'severity' => $severity->value, 'status' => 'open']);
                if ($ticket) {
                    foreach ($event->users()->get() as $recipient) {
                        $recipient->notify(new EventCareNotification(['event_id' => $event->id, 'type' => 'p1_ticket_created', 'title' => 'Critical support escalation', 'body' => $ticket->subject]));
                    }
                    EventCareChanged::dispatch($event->id, 'ticket.created', ['id' => $ticket->id, 'incident_id' => $incident->id, 'priority' => $ticket->priority->value]);
                }

                return $incident->load('ticket');
            });
        } catch (QueryException $e) {
            if ($e->getCode() === '23505') {
                throw new DomainRuleViolation('INCIDENT_ALREADY_OPEN', 'An active incident already exists for this problem.');
            }throw $e;
        }
    }
}
