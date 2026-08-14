<?php

namespace Database\Seeders;

use App\Actions\CreateIncident;
use App\Actions\UpdateIncident;
use App\Actions\UpdateTicket;
use App\Models\TicketMessage;
use App\Models\User;
use Database\Seeders\Support\DemoEventBuilder;
use Illuminate\Database\Seeder;

class DemoZurichTechnicalCupSeeder extends Seeder
{
    public function run(DemoEventBuilder $builder, CreateIncident $createIncident, UpdateIncident $updateIncident, UpdateTicket $updateTicket): void
    {
        $data = $builder->event('ZTC-2026', 'Zurich Tech Critical Cup', 'live', 12, 30, 3, 6);
        $event = $data['event'];
        $organizer = $data['organizer'];
        $support = User::query()->where('email', 'support@prowem.test')->firstOrFail();
        $builder->standardDimensions($event);
        $event->fixtures()->where('number', '<=', 12)->update(['status' => 'completed']);
        $event->fixtures()->whereIn('number', [13, 14])->update(['status' => 'live']);

        $streaming = $createIncident->execute($event, ['type' => 'technical', 'category' => 'streaming', 'severity' => 'critical', 'title' => 'Streaming unavailable', 'description' => 'Live stream unavailable on Field 1.', 'venue_id' => $data['venues'][0]->id, 'correlation_key' => 'zurich:streaming:field-1'], $organizer);
        $updateIncident->execute($streaming, ['status' => 'in_progress'], $support);
        $updateTicket->execute($streaming->ticket, ['status' => 'in_progress', 'assignee_id' => $support->id], $support);
        $streaming->ticket->update(['reference' => 'EC-ZTC-P1-001', 'created_at' => now()->subMinutes(3), 'first_response_at' => now()->subMinutes(2), 'sla_due_at' => now()->addMinutes(10)]);

        $graphics = $createIncident->execute($event, ['type' => 'technical', 'category' => 'graphics', 'severity' => 'high', 'title' => 'Graphics not updating', 'description' => 'Graphics overlays are stale on Field 2.', 'venue_id' => $data['venues'][1]->id, 'correlation_key' => 'zurich:graphics:field-2'], $support);
        $updateIncident->execute($graphics, ['status' => 'acknowledged'], $support);
        $updateTicket->execute($graphics->ticket, ['status' => 'waiting', 'assignee_id' => $support->id], $support);
        $graphics->ticket->update(['reference' => 'EC-ZTC-P1-002', 'first_response_at' => now()->subMinutes(1), 'sla_due_at' => now()->addMinutes(5)]);

        $liveScore = $createIncident->execute($event, ['type' => 'technical', 'category' => 'live_score', 'severity' => 'critical', 'title' => 'Live Score unavailable', 'description' => 'Historical live-score outage.', 'correlation_key' => 'zurich:live-score:history', 'started_at' => now()->subHours(4)], $support);
        $updateIncident->execute($liveScore, ['status' => 'in_progress'], $support);
        $updateIncident->execute($liveScore->fresh(), ['status' => 'resolved', 'resolution' => 'Live Score service restored.'], $support);
        $updateTicket->execute($liveScore->ticket, ['status' => 'in_progress', 'assignee_id' => $support->id], $support);
        $updateTicket->execute($liveScore->ticket->fresh(), ['status' => 'resolved', 'resolution' => 'Service restored.', 'resolution_code' => 'SERVICE_RESTORED'], $support);
        $liveScore->fresh()->update(['started_at' => now()->subHours(4), 'resolved_at' => now()->subHours(3)->subMinutes(35)]);
        $liveScore->ticket->update(['reference' => 'EC-ZTC-P1-003', 'created_at' => now()->subHours(4), 'first_response_at' => now()->subHours(3)->subMinutes(55), 'sla_due_at' => now()->subHours(3)->subMinutes(50), 'resolved_at' => now()->subHours(3)->subMinutes(35)]);

        $messages = [
            [$organizer, 'customer', 'Live stream is unavailable on Field 1.'],
            [$support, 'customer', 'We are investigating the streaming node.'],
            [$support, 'internal', 'Node stream-02 restarted.'],
            [$support, 'customer', 'Failover activated. Please verify.'],
            [$organizer, 'customer', 'Stream is back.'],
        ];
        for ($index = 1; $index <= 21; $index++) {
            $messages[] = [$index % 2 ? $support : $organizer, 'customer', "Diagnostic conversation update {$index}."];
        }
        foreach ($messages as $index => [$author, $visibility, $body]) {
            $message = TicketMessage::query()->create(['ticket_id' => $streaming->ticket->id, 'author_id' => $author->id, 'visibility' => $visibility, 'body' => $body, 'idempotency_key' => "ztc-message-{$index}"]);
            $message->timestamps = false;
            $message->created_at = now()->subMinutes(60 - $index * 2);
            $message->save();
        }
    }
}
