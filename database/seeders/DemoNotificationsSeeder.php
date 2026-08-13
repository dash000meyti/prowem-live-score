<?php

namespace Database\Seeders;

use App\Models\Event;
use App\Models\User;
use App\Notifications\EventCareNotification;
use Illuminate\Database\Seeder;

class DemoNotificationsSeeder extends Seeder
{
    public function run(): void
    {
        $organizer = User::query()->where('email', 'organizer@prowem.test')->firstOrFail();
        $other = User::query()->where('email', 'other-organizer@prowem.test')->firstOrFail();
        $vienna = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $salzburg = Event::query()->where('external_reference', 'SLOC-2026')->firstOrFail();
        $items = [
            [$vienna, 'critical_incident', 'Streaming unavailable on Field 2', 'Streaming incident requires attention.', false],
            [$vienna, 'p1_ticket_created', 'P1 ticket created', 'Critical streaming ticket created.', false],
            [$vienna, 'incident_created', 'Referee unavailable for Match #23', 'Tournament operations must assign a backup.', false],
            [$vienna, 'readiness_blocker', 'Salzburg United requires payment verification', 'Payment remains blocked.', false],
            [$vienna, 'roster_approved', 'Roster approved for KPMG FC', 'Roster review completed.', true],
            [$salzburg, 'readiness_confirmed', 'Field 3 readiness confirmed', 'Field inspection completed.', true],
        ];
        foreach ($items as $index => [$event, $type, $title, $body, $read]) {
            $organizer->notify(new EventCareNotification(['event_id' => $event->id, 'type' => $type, 'title' => $title, 'body' => $body]));
            $notification = $organizer->notifications()->latest()->firstOrFail();
            $notification->update(['created_at' => now()->subMinutes(10 + $index * 10), 'read_at' => $read ? now()->subMinutes(5 + $index) : null]);
        }
        $remaining = max(0, 30 - $organizer->notifications()->count());
        for ($index = 1; $index <= $remaining; $index++) {
            $organizer->notify(new EventCareNotification(['event_id' => $salzburg->id, 'type' => 'operational_update', 'title' => "Match-day update {$index}", 'body' => 'Historical notification used for inbox pagination.']));
            $notification = $organizer->notifications()->latest()->firstOrFail();
            $notification->update(['created_at' => now()->subHours(3)->subMinutes($index), 'read_at' => $index % 3 === 0 ? now()->subHours(2) : null]);
        }
        for ($index = 1; $index <= 3; $index++) {
            $other->notify(new EventCareNotification(['type' => 'private_update', 'title' => "Private account update {$index}", 'body' => 'Visible only to the secondary organizer.']));
        }
    }
}
