<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\SupportTicket;
use App\Models\Team;
use App\Models\User;
use App\Services\EventReadinessService;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DemoSeedDataTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
        $this->actingAs(User::query()->where('email', 'organizer@prowem.test')->firstOrFail());
    }

    public function test_primary_organizer_has_all_seven_scenarios_only(): void
    {
        $expected = ['VSC-2026', 'ALP-2026', 'MRC-2026', 'SLOC-2026', 'ZTC-2026', 'SPR-2026', 'GCC-2026'];
        $response = $this->getJson('/api/v1/events?per_page=100')->assertOk()->assertJsonPath('meta.pagination.total', 7);
        $this->assertEqualsCanonicalizing($expected, collect($response->json('data'))->pluck('external_reference')->all());
        $response->assertJsonMissing(['external_reference' => 'PRIVATE-2026']);
    }

    public function test_vienna_preserves_primary_team_and_incident_flow(): void
    {
        $event = $this->event('VSC-2026');
        $team = Team::query()->where('event_id', $event->id)->where('name', 'Salzburg United')->firstOrFail();
        $checkIn = $event->readinessChecks()->where('subject_id', $team->id)->where('check_type', 'check_in')->firstOrFail();
        $this->assertSame(['blocked', 'warning'], [$team->readiness_status->value, $checkIn->status->value]);
        $technical = $event->incidents()->where('type', 'technical')->where('category', 'streaming')->firstOrFail();
        $this->assertSame('in_progress', $technical->status->value);
        $this->assertSame(1, SupportTicket::query()->where('incident_id', $technical->id)->where('priority', 'p1')->count());
        $this->assertTrue($event->incidents()->where('type', 'operational')->where('category', 'referee_absent')->exists());
        $this->assertSame(2, $event->fixtures()->where('status', 'live')->count());
    }

    public function test_alpine_is_derived_blocked_and_cannot_start(): void
    {
        $event = $this->event('ALP-2026');
        $summary = app(EventReadinessService::class)->summarize($event);
        $salzburg = $event->teams()->where('name', 'Salzburg United')->firstOrFail();
        $this->assertSame('blocked', $summary['status']);
        $this->assertSame('blocked', $salzburg->readiness_status->value);
        $this->assertGreaterThanOrEqual(2, $summary['critical_blockers_count']);
        $this->assertGreaterThanOrEqual(4, $summary['actions_required_count']);
        $this->patchJson("/api/v1/events/{$event->id}/status", ['status' => 'live'])->assertConflict()->assertJsonPath('error.code', 'EVENT_NOT_READY');
    }

    public function test_munich_is_ready_and_can_start(): void
    {
        $event = $this->event('MRC-2026');
        $summary = app(EventReadinessService::class)->summarize($event);
        $this->assertSame(['ready', 100, 0, 0], [$summary['status'], $summary['score'], $summary['critical_blockers_count'], $summary['actions_required_count']]);
        $this->patchJson("/api/v1/events/{$event->id}/status", ['status' => 'live'])->assertOk()->assertJsonPath('data.status', 'live');
    }

    public function test_salzburg_is_operational_only_with_healthy_technology(): void
    {
        $event = $this->event('SLOC-2026');
        $this->assertSame(26, $event->incidents()->count());
        $this->assertSame(0, $event->incidents()->where('type', 'technical')->count());
        $this->assertSame(0, $event->tickets()->count());
        $this->assertSame(3, $event->readinessChecks()->whereIn('dimension', ['live_score', 'streaming', 'graphics'])->where('status', 'ready')->count());
        $this->assertSame(12, $event->fixtures()->where('number', 14)->value('delay_minutes'));
        $this->assertSame(3, $event->fixtures()->where('status', 'live')->count());
    }

    public function test_zurich_has_escalations_and_internal_conversation_is_hidden(): void
    {
        $event = $this->event('ZTC-2026');
        $this->assertSame(3, $event->incidents()->where('type', 'technical')->count());
        $this->assertSame(3, $event->tickets()->where('priority', 'p1')->count());
        $ticket = $event->tickets()->where('reference', 'EC-ZTC-P1-001')->firstOrFail();
        $this->assertSame(26, $ticket->messages()->count());
        $this->getJson("/api/v1/tickets/{$ticket->id}/messages?per_page=100")->assertOk()->assertJsonCount(25, 'data')->assertJsonMissing(['body' => 'Node stream-02 restarted.']);
    }

    public function test_spring_report_and_graz_cancelled_state_are_meaningful(): void
    {
        $spring = $this->event('SPR-2026');
        $this->getJson("/api/v1/events/{$spring->id}/care-report")->assertOk()->assertJsonPath('data.team_count', 16)->assertJsonPath('data.match_count', 42)->assertJsonPath('data.cancelled_matches', 1)->assertJsonPath('data.readiness.score_before_kickoff', 94)->assertJsonPath('data.incidents.operational', 4)->assertJsonPath('data.incidents.technical', 2)->assertJsonPath('data.support.tickets', 2);
        $graz = $this->event('GCC-2026');
        $this->getJson("/api/v1/events/{$graz->id}/care")->assertOk()->assertJsonPath('data.event.status', 'cancelled')->assertJsonCount(0, 'data.open_critical_incidents')->assertJsonCount(0, 'data.open_tickets');
    }

    public function test_security_and_pagination_seed_guarantees(): void
    {
        $private = $this->event('PRIVATE-2026');
        $this->getJson("/api/v1/events/{$private->id}/care")->assertForbidden();
        $organizer = User::query()->where('email', 'organizer@prowem.test')->firstOrFail();
        $other = User::query()->where('email', 'other-organizer@prowem.test')->firstOrFail();
        $this->assertSame(30, $organizer->notifications()->count());
        $this->assertSame(3, $other->notifications()->count());
        $this->assertGreaterThanOrEqual(25, $this->event('VSC-2026')->activities()->count());
        $this->assertGreaterThanOrEqual(25, $this->event('SLOC-2026')->incidents()->count());
    }

    private function event(string $reference): Event
    {
        return Event::query()->where('external_reference', $reference)->firstOrFail();
    }
}
