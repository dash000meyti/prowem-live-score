<?php

namespace Database\Seeders;

use App\Actions\CreateIncident;
use App\Actions\TransitionEvent;
use App\Actions\UpdateIncident;
use App\Actions\UpdateTicket;
use App\Enums\EventStatus;
use App\Models\Fixture;
use App\Models\ReadinessSnapshot;
use App\Models\User;
use Database\Seeders\Support\DemoEventBuilder;
use Illuminate\Database\Seeder;

class DemoSpringCupSeeder extends Seeder
{
    public function run(DemoEventBuilder $builder, TransitionEvent $transition, CreateIncident $createIncident, UpdateIncident $updateIncident, UpdateTicket $updateTicket): void
    {
        $data = $builder->event('SPR-2026', 'PROWEM Spring Cup 2026', 'ready', 16, 42, 4, 8, -120);
        $event = $data['event'];
        $organizer = $data['organizer'];
        $support = User::query()->where('email', 'support@prowem.test')->firstOrFail();
        $builder->standardDimensions($event);
        $transition->execute($event, EventStatus::Live, $organizer);
        $event->refresh();
        ReadinessSnapshot::query()->where('event_id', $event->id)->where('reason', 'before_kickoff')->update(['score' => 94, 'status' => 'ready', 'captured_at' => $event->starts_at->subMinutes(5)]);

        foreach ([
            ['operational', 'referee_absent', 'Backup referee required', 'high'],
            ['operational', 'match_delay', 'Match delayed by weather', 'medium'],
            ['operational', 'team_late', 'Team arrived late', 'low'],
            ['operational', 'venue_issue', 'Field inspection required', 'medium'],
            ['technical', 'streaming', 'Streaming interruption', 'critical'],
            ['technical', 'live_score', 'Live Score synchronization issue', 'high'],
        ] as $index => [$type, $category, $title, $severity]) {
            $incident = $createIncident->execute($event, ['type' => $type, 'category' => $category, 'severity' => $severity, 'title' => $title, 'description' => "Historical Spring Cup issue: {$title}.", 'fixture_id' => Fixture::query()->where('event_id', $event->id)->where('number', $index + 1)->value('id'), 'correlation_key' => "spring:{$category}:{$index}", 'started_at' => $event->starts_at->addHours($index + 1)], $type === 'technical' ? $support : $organizer);
            if ($type === 'technical') {
                $updateTicket->execute($incident->ticket, ['status' => 'in_progress', 'assignee_id' => $support->id], $support);
                $updateTicket->execute($incident->ticket->fresh(), ['status' => 'resolved', 'resolution' => 'Service restored.', 'resolution_code' => 'RESTORED'], $support);
                $incident->ticket->update(['reference' => 'EC-SPR-P1-00'.($index - 3), 'created_at' => $event->starts_at->addHours($index + 1), 'first_response_at' => $event->starts_at->addHours($index + 1)->addMinutes(4), 'sla_due_at' => $event->starts_at->addHours($index + 1)->addMinutes(6), 'resolved_at' => $event->starts_at->addHours($index + 1)->addMinutes(18)]);
            }
            $updateIncident->execute($incident, ['status' => 'resolved', 'resolution' => $category === 'referee_absent' ? 'Backup referee assigned.' : 'Issue resolved during event operations.'], $type === 'technical' ? $support : $organizer);
            $incident->update(['started_at' => $event->starts_at->addHours($index + 1), 'resolved_at' => $event->starts_at->addHours($index + 1)->addMinutes(20)]);
        }
        Fixture::query()->where('event_id', $event->id)->where('number', 42)->update(['status' => 'cancelled']);
        Fixture::query()->where('event_id', $event->id)->whereIn('number', [4, 8, 12, 16, 20])->update(['delay_minutes' => 8]);
        Fixture::query()->where('event_id', $event->id)->where('status', 'scheduled')->update(['status' => 'completed']);
        $transition->execute($event->fresh(), EventStatus::Completed, $organizer);
        $event->update(['completed_at' => $event->ends_at->addMinutes(12)]);
    }
}
