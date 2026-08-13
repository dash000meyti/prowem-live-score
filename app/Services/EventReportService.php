<?php

namespace App\Services;

use App\Enums\IncidentType;
use App\Enums\TicketPriority;
use App\Models\Event;
use App\Models\ReadinessSnapshot;

final class EventReportService
{
    public function build(Event $event): array
    {
        $incidents = $event->incidents()->get();
        $tickets = $event->tickets()->get();
        $fixtures = $event->fixtures();
        $resolved = $tickets->whereNotNull('resolved_at');
        $slaMeasured = $tickets->filter(fn ($t) => $t->first_response_at !== null || now()->greaterThan($t->sla_due_at));
        $slaMet = $slaMeasured->filter(fn ($t) => $t->first_response_at && $t->first_response_at <= $t->sla_due_at)->count();
        $recommendations = [];
        if ($incidents->where('category', 'streaming')->count() > 0) {
            $recommendations[] = 'Run a streaming failover rehearsal before the next event.';
        }if ($incidents->where('category', 'referee_absent')->count() > 0) {
            $recommendations[] = 'Confirm backup referee availability before kickoff.';
        }if ($recommendations === []) {
            $recommendations[] = 'No recurring critical issue was detected; retain the current readiness process.';
        }

        $snapshot = ReadinessSnapshot::query()->where('event_id', $event->id)->where('reason', 'before_kickoff')->latest('captured_at')->first();

        return ['event' => ['id' => (int) $event->id, 'name' => $event->name, 'status' => $event->status->value], 'team_count' => (int) $event->teams()->count(), 'match_count' => (int) (clone $fixtures)->count(), 'readiness' => ['score_before_kickoff' => $snapshot?->score, 'status_before_kickoff' => $snapshot?->status?->value], 'incidents' => ['total' => (int) $incidents->count(), 'operational' => (int) $incidents->where('type', IncidentType::Operational)->count(), 'technical' => (int) $incidents->where('type', IncidentType::Technical)->count()], 'cancelled_matches' => (int) (clone $fixtures)->where('status', 'cancelled')->count(), 'average_delay_minutes' => (float) ((clone $fixtures)->avg('delay_minutes') ?? 0), 'support' => ['tickets' => (int) $tickets->count(), 'p1' => (int) $tickets->where('priority', TicketPriority::P1)->count(), 'sla_compliance_percent' => $slaMeasured->isEmpty() ? null : (float) round($slaMet / $slaMeasured->count() * 100, 1), 'average_resolution_minutes' => $resolved->isEmpty() ? null : (float) $resolved->avg(fn ($t) => $t->created_at->diffInMinutes($t->resolved_at))], 'major_blockers' => $event->readinessChecks()->where('is_critical', true)->where('status', 'blocked')->get()->map(fn ($c) => ['key' => $c->check_type, 'message' => $c->message, 'error_code' => $c->error_code])->values()->all(), 'recommendations' => array_values($recommendations)];
    }
}
