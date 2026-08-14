<?php

namespace Tests\Feature;

use App\Enums\EventStatus;
use App\Enums\UserRole;
use App\Events\EventCareChanged;
use App\Models\Account;
use App\Models\Event;
use App\Models\Incident;
use App\Models\ReadinessCheck;
use App\Models\SupportTicket;
use App\Models\Team;
use App\Models\TicketMessage;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event as EventFacade;
use Tests\TestCase;

class SecurityAndBehaviorTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
        EventFacade::fake([EventCareChanged::class]);
    }

    public function test_team_operation_persists_business_fact_before_projecting_readiness(): void
    {
        $event = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $team = $event->teams()->where('name', 'Salzburg United')->firstOrFail();
        $this->actingAs($this->organizer())->postJson("/api/v1/events/{$event->id}/teams/{$team->id}/actions/verify_payment")->assertOk();

        $this->assertDatabaseHas('team_operation_states', ['event_id' => $event->id, 'team_id' => $team->id, 'operation' => 'verify_payment']);
        $this->assertSame('ready', ReadinessCheck::query()->where('event_id', $event->id)->where('subject_id', $team->id)->where('check_type', 'payment')->firstOrFail()->status->value);
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'team.readiness.changed');
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'event.readiness.changed');
    }

    public function test_invalid_team_operation_and_dimension_have_stable_errors(): void
    {
        $event = Event::query()->firstOrFail();
        $team = $event->teams()->firstOrFail();
        $this->actingAs($this->organizer());
        $this->postJson("/api/v1/events/{$event->id}/teams/{$team->id}/actions/hack")->assertUnprocessable()->assertJsonPath('error.code', 'INVALID_TEAM_OPERATION');
        $this->getJson("/api/v1/events/{$event->id}/readiness/hack")->assertUnprocessable()->assertJsonPath('error.code', 'INVALID_READINESS_DIMENSION');
    }

    public function test_organizer_cannot_administer_ticket_or_create_internal_message(): void
    {
        $ticket = SupportTicket::query()->firstOrFail();
        $this->actingAs($this->organizer());
        $this->patchJson("/api/v1/tickets/{$ticket->id}", ['priority' => 'p4', 'assignee_id' => 2, 'internal_note' => 'private'])->assertForbidden()->assertJsonPath('error.code', 'FORBIDDEN');
        $this->postJson("/api/v1/tickets/{$ticket->id}/messages", ['body' => 'Hidden note', 'visibility' => 'internal'])->assertUnprocessable()->assertJsonPath('error.code', 'VALIDATION_FAILED');
        $this->assertDatabaseMissing('ticket_messages', ['body' => 'Hidden note']);
    }

    public function test_support_internal_message_is_never_exposed_to_organizer(): void
    {
        $ticket = SupportTicket::query()->firstOrFail();
        $agent = User::query()->where('role', UserRole::SupportAgent)->firstOrFail();
        $this->actingAs($agent)->postJson("/api/v1/tickets/{$ticket->id}/messages", ['body' => 'Support-only detail', 'visibility' => 'internal'])->assertCreated();
        $this->actingAs($this->organizer())->getJson("/api/v1/tickets/{$ticket->id}/messages")->assertOk()->assertJsonMissing(['body' => 'Support-only detail']);
        $this->getJson("/api/v1/tickets/{$ticket->id}")->assertOk()->assertJsonMissingPath('data.internal_note');
    }

    public function test_customer_message_and_resolutions_emit_distinct_realtime_names(): void
    {
        $ticket = SupportTicket::query()->firstOrFail();
        $this->actingAs($this->organizer())->postJson("/api/v1/tickets/{$ticket->id}/messages", ['body' => 'Any update?'])->assertCreated();
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'ticket.message.created');
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'activity.created');

        $agent = User::query()->where('role', UserRole::SupportAgent)->firstOrFail();
        $this->actingAs($agent)->patchJson("/api/v1/tickets/{$ticket->id}", ['status' => 'in_progress'])->assertOk();
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'ticket.updated');
        $this->actingAs($agent)->patchJson("/api/v1/tickets/{$ticket->id}", ['status' => 'resolved', 'resolution' => 'Service restored.', 'resolution_code' => 'RESTORED'])->assertOk();
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'ticket.resolved');

        $event = Event::query()->where('external_reference', 'ZTC-2026')->firstOrFail();
        $incidentResponse = $this->postJson("/api/v1/events/{$event->id}/incidents", ['type' => 'technical', 'category' => 'platform', 'severity' => 'medium', 'title' => 'Realtime lifecycle test', 'description' => 'Test incident.', 'correlation_key' => 'realtime:lifecycle'])->assertCreated();
        $incident = Incident::query()->findOrFail($incidentResponse->json('data.id'));
        $this->patchJson("/api/v1/incidents/{$incident->id}", ['status' => 'acknowledged'])->assertOk();
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'incident.updated');
        $this->patchJson("/api/v1/incidents/{$incident->id}", ['status' => 'resolved', 'resolution' => 'Stream restored.'])->assertOk();
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'incident.resolved');
    }

    public function test_event_transition_broadcasts_status_change(): void
    {
        $event = Event::query()->where('external_reference', 'ALP-2026')->firstOrFail();
        $this->actingAs($this->organizer())->patchJson("/api/v1/events/{$event->id}/status", ['status' => 'ready'])->assertOk();
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'event.status.changed');
    }

    public function test_live_technical_incident_transactionally_escalates_once(): void
    {
        $event = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $payload = ['type' => 'technical', 'category' => 'platform', 'severity' => 'high', 'title' => 'Platform unavailable', 'description' => 'Operations API is unavailable.', 'correlation_key' => 'platform:stage3'];
        $this->actingAs($this->organizer());
        $response = $this->postJson("/api/v1/events/{$event->id}/incidents", $payload)->assertCreated()->assertJsonPath('data.ticket.priority', 'p1');
        $incidentId = $response->json('data.id');
        $ticket = SupportTicket::query()->where('incident_id', $incidentId)->firstOrFail();

        $this->assertSame(1, SupportTicket::query()->where('incident_id', $incidentId)->count());
        $this->assertTrue($ticket->sla_due_at->greaterThan($ticket->created_at));
        $this->assertDatabaseHas('activities', ['event_id' => $event->id, 'type' => 'support_ticket_created']);
        $this->assertGreaterThan(0, $event->users()->firstOrFail()->notifications()->count());
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'incident.created');
        EventFacade::assertDispatched(EventCareChanged::class, fn ($event) => $event->name === 'ticket.created');

        $this->postJson("/api/v1/events/{$event->id}/incidents", $payload)->assertConflict()->assertJsonPath('error.code', 'INCIDENT_ALREADY_OPEN');
        $this->assertSame(1, Incident::query()->where('correlation_key', 'platform:stage3')->count());
        $this->assertSame(1, SupportTicket::query()->where('incident_id', $incidentId)->count());
    }

    public function test_organizer_is_denied_all_other_customer_resources(): void
    {
        $account = Account::query()->create(['name' => 'Private Account', 'plan' => 'standard']);
        $event = Event::query()->create(['account_id' => $account->id, 'name' => 'Private Event', 'status' => EventStatus::Preparing, 'starts_at' => now(), 'ends_at' => now()->addDay()]);
        $team = Team::query()->create(['event_id' => $event->id, 'name' => 'Private Team']);
        $incident = Incident::query()->create(['event_id' => $event->id, 'type' => 'operational', 'category' => 'other', 'severity' => 'low', 'status' => 'open', 'title' => 'Private', 'description' => 'Private', 'started_at' => now()]);
        $ticket = SupportTicket::query()->create(['event_id' => $event->id, 'priority' => 'p3', 'status' => 'open', 'subject' => 'Private', 'description' => 'Private', 'sla_due_at' => now()->addHour()]);
        TicketMessage::query()->create(['ticket_id' => $ticket->id, 'visibility' => 'customer', 'body' => 'Private message']);
        $this->actingAs($this->organizer());

        foreach (["/api/v1/events/{$event->id}/care", "/api/v1/events/{$event->id}/readiness", "/api/v1/events/{$event->id}/teams/{$team->id}/readiness", "/api/v1/events/{$event->id}/incidents", "/api/v1/incidents/{$incident->id}", "/api/v1/events/{$event->id}/tickets", "/api/v1/tickets/{$ticket->id}", "/api/v1/tickets/{$ticket->id}/messages", "/api/v1/events/{$event->id}/activity", "/api/v1/events/{$event->id}/care-report"] as $url) {
            $this->getJson($url)->assertForbidden();
        }
    }

    public function test_private_event_broadcast_channel_enforces_customer_ownership(): void
    {
        $own = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $otherAccount = Account::query()->create(['name' => 'Other', 'plan' => 'standard']);
        $other = Event::query()->create(['account_id' => $otherAccount->id, 'name' => 'Other Event', 'status' => 'preparing', 'starts_at' => now(), 'ends_at' => now()->addDay()]);
        $this->actingAs($this->organizer());

        $this->postJson('/api/v1/broadcasting/auth', ['socket_id' => '123.456', 'channel_name' => "private-events.{$own->id}"])->assertOk();
        $this->postJson('/api/v1/broadcasting/auth', ['socket_id' => '123.456', 'channel_name' => "private-events.{$other->id}"])->assertForbidden();
    }

    public function test_other_users_notification_cannot_be_marked_read(): void
    {
        $other = User::query()->where('email', 'support@prowem.test')->firstOrFail();
        $notification = $other->notifications()->firstOrFail();
        $this->actingAs($this->organizer())->patchJson("/api/v1/notifications/{$notification->id}/read")->assertNotFound();
    }

    private function organizer(): User
    {
        return User::query()->where('email', 'organizer@prowem.test')->firstOrFail();
    }
}
