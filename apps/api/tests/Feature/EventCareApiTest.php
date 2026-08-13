<?php

namespace Tests\Feature;

use App\Enums\ReadinessStatus;
use App\Events\EventCareChanged;
use App\Models\Event;
use App\Models\Incident;
use App\Models\ReadinessCheck;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event as EventFacade;
use Tests\TestCase;

class EventCareApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
        EventFacade::fake([EventCareChanged::class]);
    }

    public function test_authentication_and_success_envelope(): void
    {
        $response = $this->postJson('/api/v1/auth/login', ['email' => 'organizer@prowem.test', 'password' => 'password']);
        $response->assertOk()->assertJsonStructure(['success', 'message', 'data' => ['token', 'user']])->assertJsonPath('success', true);
    }

    public function test_unauthenticated_error_envelope(): void
    {
        $this->getJson('/api/v1/events/1/care')->assertUnauthorized()->assertJson(['success' => false, 'error' => ['code' => 'UNAUTHENTICATED']]);
    }

    public function test_dashboard_and_paginated_contracts(): void
    {
        $this->actingAs($this->organizer());
        $event = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $this->getJson("/api/v1/events/{$event->id}/care")->assertOk()->assertJsonStructure(['success', 'message', 'data' => ['event', 'readiness', 'open_critical_incidents', 'open_tickets', 'recent_activity']]);
        $this->getJson("/api/v1/events/{$event->id}/incidents?per_page=1&type=technical")->assertOk()->assertJsonStructure(['success', 'message', 'data', 'meta' => ['pagination' => ['current_page', 'per_page', 'total', 'last_page', 'from', 'to']], 'links' => ['first', 'last', 'prev', 'next']]);
    }

    public function test_organizer_cannot_bypass_payment_business_action_with_generic_patch(): void
    {
        $this->actingAs($this->organizer());
        $check = ReadinessCheck::query()->where('check_type', 'payment')->firstOrFail();
        $this->patchJson("/api/v1/readiness-checks/{$check->id}", ['status' => 'ready', 'message' => 'Payment verified.', 'reason' => 'Manual bypass'])->assertForbidden()->assertJsonPath('error.code', 'FORBIDDEN');
        $this->assertSame(ReadinessStatus::Blocked, $check->fresh()->status);
    }

    public function test_critical_blocker_prevents_invalid_go_live_transition(): void
    {
        $this->actingAs($this->organizer());
        $event = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $event->update(['status' => 'ready']);
        $this->patchJson("/api/v1/events/{$event->id}/status", ['status' => 'live'])->assertConflict()->assertJson(['success' => false, 'error' => ['code' => 'EVENT_NOT_READY']]);
    }

    public function test_duplicate_technical_incident_is_rejected_and_only_one_ticket_exists(): void
    {
        $this->actingAs(User::query()->where('email', 'support@prowem.test')->firstOrFail());
        $event = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $payload = ['type' => 'technical', 'category' => 'streaming', 'severity' => 'critical', 'title' => 'Streaming unavailable', 'description' => 'Health check failed.', 'correlation_key' => 'streaming:field-2'];
        $this->postJson("/api/v1/events/{$event->id}/incidents", $payload)->assertConflict()->assertJsonPath('error.code', 'INCIDENT_ALREADY_OPEN');
        $this->assertSame(1, $event->tickets()->count());
    }

    public function test_operational_incident_lifecycle_and_report(): void
    {
        $this->actingAs($this->organizer());
        $incident = Incident::query()->where('type', 'operational')->firstOrFail();
        $this->patchJson("/api/v1/incidents/{$incident->id}", ['status' => 'resolved', 'resolution' => 'Backup referee assigned.'])->assertOk()->assertJsonPath('data.status', 'resolved');
        $event = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $this->getJson("/api/v1/events/{$event->id}/care-report")->assertOk()->assertJsonStructure(['success', 'message', 'data' => ['team_count', 'match_count', 'incidents', 'support', 'recommendations']]);
    }

    public function test_event_lookups_include_fixtures_and_hide_staff_from_organizer(): void
    {
        $event = Event::query()->where('external_reference', 'VSC-2026')->firstOrFail();
        $this->actingAs($this->organizer())->getJson("/api/v1/events/{$event->id}/lookups")
            ->assertOk()
            ->assertJsonStructure(['success', 'data' => ['venues', 'fixtures' => [['id', 'number', 'kickoff_at', 'home_team', 'away_team']], 'staff']])
            ->assertJsonPath('data.staff', []);
        $this->actingAs(User::query()->where('email', 'support@prowem.test')->firstOrFail())
            ->getJson("/api/v1/events/{$event->id}/lookups")
            ->assertOk()
            ->assertJsonCount(3, 'data.staff');
        $private = Event::query()->where('external_reference', 'PRIVATE-2026')->firstOrFail();
        $this->actingAs($this->organizer())->getJson("/api/v1/events/{$private->id}/lookups")->assertForbidden()->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_validation_and_not_found_contracts(): void
    {
        $this->actingAs($this->organizer());
        $event = Event::query()->firstOrFail();
        $this->postJson("/api/v1/events/{$event->id}/incidents", [])->assertUnprocessable()->assertJsonStructure(['success', 'message', 'error' => ['code', 'details']]);
        $this->getJson('/api/v1/incidents/999999')->assertNotFound()->assertJsonPath('error.code', 'RESOURCE_NOT_FOUND');
    }

    private function organizer(): User
    {
        return User::query()->where('email', 'organizer@prowem.test')->firstOrFail();
    }
}
