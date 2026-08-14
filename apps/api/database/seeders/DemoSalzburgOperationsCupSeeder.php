<?php

namespace Database\Seeders;

use App\Actions\CreateIncident;
use App\Actions\UpdateIncident;
use App\Models\Fixture;
use Database\Seeders\Support\DemoEventBuilder;
use Illuminate\Database\Seeder;

class DemoSalzburgOperationsCupSeeder extends Seeder
{
    public function run(DemoEventBuilder $builder, CreateIncident $createIncident, UpdateIncident $updateIncident): void
    {
        $data = $builder->event('SLOC-2026', 'Salzburg Live Operations Cup', 'live', 20, 52, 5, 10);
        $event = $data['event'];
        $organizer = $data['organizer'];
        $builder->standardDimensions($event);
        Fixture::query()->where('event_id', $event->id)->where('number', '<=', 17)->update(['status' => 'completed']);
        Fixture::query()->where('event_id', $event->id)->whereIn('number', [18, 19, 20])->update(['status' => 'live']);
        Fixture::query()->where('event_id', $event->id)->where('number', 22)->update(['kickoff_at' => now()->addMinutes(7)]);
        $data['teams'][0]->update(['name' => 'FC Linz']);

        $definitions = [
            ['team_late', 'FC Linz is late', 18, 'high', 'open', null],
            ['referee_absent', 'Referee absent for Match #22', 22, 'critical', 'acknowledged', null],
            ['match_delay', 'Match #14 delayed', 14, 'medium', 'in_progress', null],
            ['venue_issue', 'Field 4 unavailable', null, 'high', 'open', null],
            ['team_absent', 'Team absence resolved', 9, 'medium', 'resolved', 'Replacement team confirmed and fixture retained.'],
        ];
        foreach ($definitions as [$category, $title, $number, $severity, $status, $resolution]) {
            $fixture = $number ? Fixture::query()->where('event_id', $event->id)->where('number', $number)->firstOrFail() : null;
            if ($category === 'match_delay') {
                $fixture->update(['delay_minutes' => 12]);
            }
            $incident = $createIncident->execute($event, ['type' => 'operational', 'category' => $category, 'severity' => $severity, 'title' => $title, 'description' => "Demo operational issue: {$title}.", 'fixture_id' => $fixture?->id, 'venue_id' => $category === 'venue_issue' ? $data['venues'][3]->id : $fixture?->venue_id, 'correlation_key' => "salzburg:{$category}:".($number ?? 4)], $organizer);
            if ($status === 'acknowledged') {
                $updateIncident->execute($incident, ['status' => 'acknowledged'], $organizer);
            } elseif ($status === 'in_progress') {
                $updateIncident->execute($incident, ['status' => 'in_progress'], $organizer);
            } elseif ($status === 'resolved') {
                $updateIncident->execute($incident, ['status' => 'resolved', 'resolution' => $resolution], $organizer);
            }
        }

        for ($index = 1; $index <= 21; $index++) {
            $incident = $createIncident->execute($event, ['type' => 'operational', 'category' => $index % 2 ? 'team_late' : 'match_delay', 'severity' => $index % 3 ? 'low' : 'medium', 'title' => "Resolved operational issue {$index}", 'description' => 'Historical match-day issue used for pagination.', 'fixture_id' => Fixture::query()->where('event_id', $event->id)->where('number', ($index % 52) + 1)->value('id'), 'correlation_key' => "salzburg:history:{$index}", 'started_at' => now()->subDays(2)->addMinutes($index)], $organizer);
            $updateIncident->execute($incident, ['status' => 'resolved', 'resolution' => 'Resolved by tournament operations.'], $organizer);
        }
    }
}
