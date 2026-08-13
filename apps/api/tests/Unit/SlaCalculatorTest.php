<?php

namespace Tests\Unit;

use App\Enums\TicketPriority;
use App\Services\SlaCalculator;
use Carbon\CarbonImmutable;
use PHPUnit\Framework\TestCase;

class SlaCalculatorTest extends TestCase
{
    public function test_live_premium_p1_has_fast_response_deadline(): void
    {
        $from = CarbonImmutable::parse('2026-08-15 10:00:00');
        $due = (new SlaCalculator)->responseDeadline(TicketPriority::P1, 'premium', true, $from);
        $this->assertSame('2026-08-15 10:06:00', $due->format('Y-m-d H:i:s'));
    }

    public function test_reports_breached_sla(): void
    {
        CarbonImmutable::setTestNow('2026-08-15 11:00:00');
        $this->assertSame('breached', (new SlaCalculator)->state(null, CarbonImmutable::parse('2026-08-15 10:30:00')));
        CarbonImmutable::setTestNow();
    }

    public function test_p2_deadline_and_approaching_state(): void
    {
        $from = CarbonImmutable::parse('2026-08-15 10:00:00');
        $due = (new SlaCalculator)->responseDeadline(TicketPriority::P2, 'standard', false, $from);
        $this->assertSame('2026-08-15 11:00:00', $due->format('Y-m-d H:i:s'));
        CarbonImmutable::setTestNow('2026-08-15 10:50:00');
        $this->assertSame('approaching', (new SlaCalculator)->state(null, $due));
        CarbonImmutable::setTestNow();
    }

    public function test_resolved_response_reports_met_or_breached(): void
    {
        $due = CarbonImmutable::parse('2026-08-15 11:00:00');
        $this->assertSame('met', (new SlaCalculator)->state(CarbonImmutable::parse('2026-08-15 10:59:00'), $due));
        $this->assertSame('breached', (new SlaCalculator)->state(CarbonImmutable::parse('2026-08-15 11:01:00'), $due));
    }
}
