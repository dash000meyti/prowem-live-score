<?php

namespace Database\Seeders;

use App\Actions\CreateIncident;
use App\Actions\UpdateIncident;
use App\Enums\ReadinessStatus;
use App\Models\Activity;
use App\Models\Fixture;
use App\Models\User;
use Database\Seeders\Support\DemoEventBuilder;
use Illuminate\Database\Seeder;

class DemoViennaSummerCupSeeder extends Seeder
{
    public function run(DemoEventBuilder $builder, CreateIncident $createIncident, UpdateIncident $updateIncident): void
    {
        $data = $builder->event('VSC-2026', 'Vienna Summer Cup 2026', 'live', 16, 42, 4, 8);
        $event = $data['event'];
        $organizer = $data['organizer'];
        $support = User::query()->where('email', 'support@prowem.test')->firstOrFail();
        $salzburg = $data['teams']->first();
        $salzburg->update(['name' => 'Salzburg United', 'manager_name' => 'Martin Berger', 'manager_phone' => '+43 660 123456']);
        $data['teams'][1]->update(['name' => 'KPMG FC']);
        $builder->teamChecks($event, $salzburg, ['registration' => ReadinessStatus::Ready, 'payment' => ReadinessStatus::Blocked, 'roster' => ReadinessStatus::Ready, 'eligibility' => ReadinessStatus::Ready, 'documents' => ReadinessStatus::Ready, 'check_in' => ReadinessStatus::Warning]);
        $builder->standardDimensions($event);
        Fixture::query()->where('event_id', $event->id)->where('number', '<=', 20)->update(['status' => 'completed']);
        Fixture::query()->where('event_id', $event->id)->whereIn('number', [21, 22])->update(['status' => 'live']);
        $streamingCheck = $event->readinessChecks()->where('dimension', 'streaming')->firstOrFail();
        $streamingCheck->update(['status' => ReadinessStatus::Blocked, 'message' => 'Streaming unavailable on Field 2.', 'error_code' => 'STREAMING_UNAVAILABLE', 'metadata' => ['venue_id' => $data['venues'][1]->id]]);

        $fixture = Fixture::query()->where('event_id', $event->id)->where('number', 23)->firstOrFail();
        $fixture->update(['venue_id' => $data['venues'][2]->id, 'kickoff_at' => now()->addMinutes(7)]);
        $operational = $createIncident->execute($event, ['type' => 'operational', 'category' => 'referee_absent', 'severity' => 'high', 'title' => 'Referee unavailable', 'description' => 'Assigned referee unavailable for Match #23.', 'fixture_id' => $fixture->id, 'venue_id' => $data['venues'][2]->id, 'correlation_key' => 'vienna:referee:23'], $organizer);
        $updateIncident->execute($operational, ['status' => 'acknowledged'], $organizer);

        $technical = $createIncident->execute($event, ['type' => 'technical', 'category' => 'streaming', 'severity' => 'critical', 'title' => 'Streaming unavailable', 'description' => 'Streaming unavailable on Field 2.', 'venue_id' => $data['venues'][1]->id, 'correlation_key' => 'streaming:field-2'], $support);
        $updateIncident->execute($technical, ['status' => 'in_progress'], $support);
        $technical->ticket->update(['reference' => 'EC-VSC-P1-001', 'first_response_at' => now()->subMinutes(2), 'assignee_id' => $support->id]);

        $timeline = ['Payment verification requested for Salzburg United', 'Roster approved for KPMG FC', 'Backup referee contacted', 'Backup referee assigned', 'Field 3 readiness confirmed', 'Support acknowledged streaming incident', 'Streaming failover diagnostics started'];
        foreach ($timeline as $index => $description) {
            Activity::query()->create(['event_id' => $event->id, 'actor_id' => $index % 2 ? $support->id : $organizer->id, 'type' => $index === 0 ? 'readiness_check_changed' : 'operational_update', 'description' => $description, 'context' => ['demo' => true], 'occurred_at' => now()->subMinutes(90 - $index * 8)]);
        }
        for ($index = 1; $index <= 22; $index++) {
            Activity::query()->create(['event_id' => $event->id, 'actor_id' => $organizer->id, 'type' => 'operational_update', 'description' => "Match-day checkpoint {$index} completed.", 'context' => ['checkpoint' => $index], 'occurred_at' => now()->subMinutes(300 - $index * 5)]);
        }
    }
}
