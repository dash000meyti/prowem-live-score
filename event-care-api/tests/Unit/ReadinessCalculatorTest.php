<?php

namespace Tests\Unit;

use App\Enums\ReadinessStatus;
use App\Services\ReadinessCalculator;
use PHPUnit\Framework\TestCase;

class ReadinessCalculatorTest extends TestCase
{
    public function test_blocked_propagates_and_critical_blocker_overrides_high_score(): void
    {
        $checks = collect(array_merge(array_fill(0, 24, (object) ['status' => ReadinessStatus::Ready, 'is_critical' => false]), [(object) ['status' => ReadinessStatus::Blocked, 'is_critical' => true]]));
        $result = (new ReadinessCalculator)->calculate($checks);
        $this->assertSame(ReadinessStatus::Blocked, $result['status']);
        $this->assertSame(96, $result['score']);
        $this->assertSame(1, $result['critical_blockers_count']);
    }

    public function test_warning_propagates_without_blocker(): void
    {
        $result = (new ReadinessCalculator)->calculate(collect([(object) ['status' => ReadinessStatus::Ready, 'is_critical' => true], (object) ['status' => ReadinessStatus::Warning, 'is_critical' => false]]));
        $this->assertSame(ReadinessStatus::Warning, $result['status']);
        $this->assertSame(75, $result['score']);
    }
}
