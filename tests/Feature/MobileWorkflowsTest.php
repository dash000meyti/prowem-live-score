<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Events\EventCareChanged;
use App\Models\Account;
use App\Models\Event;
use App\Models\ReadinessCheck;
use App\Models\SupportTicket;
use App\Models\Team;
use App\Models\TicketMessage;
use App\Models\User;
use App\Notifications\EventCareNotification;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event as EventFacade;
use Tests\TestCase;

class MobileWorkflowsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
        EventFacade::fake([EventCareChanged::class]);
    }

    public function test_me_and_my_events_are_mobile_ready_and_paginated(): void
    {
        $this->actingAs($this->organizer());
        $this->getJson('/api/v1/me')->assertOk()->assertJsonPath('data.role', 'organizer')->assertJsonPath('data.customer.name', 'Vienna Football Association');
        $this->getJson('/api/v1/events?status=live&per_page=2')->assertOk()->assertJsonCount(2, 'data')->assertJsonPath('meta.pagination.total', 3)->assertJsonStructure(['data' => [['readiness', 'teams_count', 'fields_count', 'open_incidents_count']], 'meta' => ['pagination'], 'links']);
        $this->getJson('/api/v1/events?status=live')->assertJsonStructure([
            'data' => [[
                'venue' => ['id', 'name'],
                'readiness' => ['status', 'score', 'critical_blockers_count', 'actions_required_count'],
            ]],
        ]);
    }

    public function test_my_events_and_event_resources_enforce_customer_ownership(): void
    {
        $other = Account::query()->create(['name' => 'Other', 'plan' => 'standard']);
        $event = Event::query()->create(['account_id' => $other->id, 'name' => 'Private Cup', 'status' => 'preparing', 'starts_at' => now(), 'ends_at' => now()->addDay()]);
        $this->actingAs($this->organizer());
        $this->getJson('/api/v1/events')->assertOk()->assertJsonMissing(['name' => 'Private Cup']);
        $this->getJson("/api/v1/events/{$event->id}/care")->assertForbidden();
    }

    public function test_team_business_actions_are_idempotent_and_propagate_readiness(): void
    {
        $this->actingAs($this->organizer());
        $event = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $team = Team::query()->where('name', 'Salzburg United')->firstOrFail();
        $url = "/api/v1/events/{$event->id}/teams/{$team->id}/actions/verify_payment";
        $this->postJson($url)->assertOk()->assertJsonPath('data.checks.3.status', 'ready');
        $this->postJson($url)->assertOk();
        $this->assertDatabaseCount('team_operation_states', 1);
        $this->assertSame('ready', ReadinessCheck::query()->where('event_id', $event->id)->where('subject_id', $team->id)->where('check_type', 'payment')->firstOrFail()->status->value);
        $this->assertDatabaseHas('activities', ['type' => 'team_operation_completed']);
        EventFacade::assertDispatched(EventCareChanged::class);
    }

    public function test_manual_support_applies_priority_policy_and_is_idempotent(): void
    {
        $this->actingAs($this->organizer());
        $event = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $payload = ['category' => 'technical_help', 'requested_urgency' => 'critical', 'affected_service' => 'streaming', 'subject' => 'Field stream unavailable', 'description' => 'Please investigate.', 'idempotency_key' => 'mobile-retry-1'];
        $this->postJson("/api/v1/events/{$event->id}/tickets", $payload)->assertCreated()->assertJsonPath('data.priority', 'p1');
        $this->postJson("/api/v1/events/{$event->id}/tickets", $payload)->assertCreated();
        $this->assertSame(1, SupportTicket::query()->where('idempotency_key', 'mobile-retry-1')->count());
    }

    public function test_requested_critical_does_not_grant_p1_outside_live_service_policy(): void
    {
        $this->actingAs($this->organizer());
        $event = Event::query()->where('external_reference', 'ALP-2026')->firstOrFail();
        $payload = ['category' => 'technical_help', 'requested_urgency' => 'critical', 'affected_service' => 'streaming', 'subject' => 'Pre-event setup help', 'description' => 'Streaming setup needs review.'];
        $this->postJson("/api/v1/events/{$event->id}/tickets", $payload)->assertCreated()->assertJsonPath('data.priority', 'p2');
    }

    public function test_customer_never_receives_internal_ticket_messages(): void
    {
        $ticket = SupportTicket::query()->firstOrFail();
        $agent = User::query()->where('role', UserRole::SupportAgent)->firstOrFail();
        TicketMessage::query()->create(['ticket_id' => $ticket->id, 'author_id' => $agent->id, 'visibility' => 'internal', 'body' => 'Private escalation']);
        TicketMessage::query()->create(['ticket_id' => $ticket->id, 'author_id' => $agent->id, 'visibility' => 'customer', 'body' => 'We are investigating']);
        $this->actingAs($this->organizer());
        $this->getJson("/api/v1/tickets/{$ticket->id}/messages")->assertOk()->assertJsonCount(1, 'data')->assertJsonMissing(['body' => 'Private escalation']);
    }

    public function test_notifications_are_isolated_and_can_be_read(): void
    {
        $user = $this->organizer();
        $user->notifications()->delete();
        $user->notify(new EventCareNotification(['type' => 'incident_created', 'title' => 'Issue', 'body' => 'One issue']));
        $other = User::query()->where('email', 'support@prowem.test')->firstOrFail();
        $other->notify(new EventCareNotification(['type' => 'private', 'title' => 'Private', 'body' => 'Hidden']));
        $this->actingAs($user);
        $response = $this->getJson('/api/v1/notifications')->assertOk()->assertJsonCount(1, 'data')->assertJsonMissing(['title' => 'Private']);
        $id = $response->json('data.0.id');
        $this->patchJson("/api/v1/notifications/{$id}/read")->assertOk();
        $this->postJson('/api/v1/notifications/read-all')->assertOk();
    }

    public function test_report_uses_historical_readiness_snapshot(): void
    {
        $this->actingAs($this->organizer());
        $event = Event::query()->where('external_reference', 'SPR-2026')->firstOrFail();
        $this->getJson("/api/v1/events/{$event->id}/care-report")->assertOk()->assertJsonPath('data.readiness.score_before_kickoff', 94)->assertJsonPath('data.match_count', 42)->assertJsonPath('data.cancelled_matches', 1)->assertJsonPath('data.support.tickets', 2);
    }

    private function organizer(): User
    {
        return User::query()->where('email', 'organizer@prowem.test')->firstOrFail();
    }
}
