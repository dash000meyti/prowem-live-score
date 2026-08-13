<?php

namespace App\Services;

use App\Enums\ReadinessStatus;
use Illuminate\Support\Collection;

final class ReadinessCalculator
{
    /** @param Collection<int, object{status:ReadinessStatus,is_critical:bool}> $checks */
    public function calculate(Collection $checks): array
    {
        if ($checks->isEmpty()) {
            return ['status' => ReadinessStatus::Ready, 'score' => 100, 'critical_blockers_count' => 0];
        }
        $critical = $checks->filter(fn ($c) => $c->is_critical && $c->status === ReadinessStatus::Blocked)->count();
        $status = $critical > 0 || $checks->contains(fn ($c) => $c->status === ReadinessStatus::Blocked) ? ReadinessStatus::Blocked : ($checks->contains(fn ($c) => $c->status === ReadinessStatus::Warning) ? ReadinessStatus::Warning : ReadinessStatus::Ready);
        $points = $checks->sum(fn ($c) => match ($c->status) {
            ReadinessStatus::Ready => 100,ReadinessStatus::Warning => 50,ReadinessStatus::Blocked => 0
        });

        return ['status' => $status, 'score' => (int) round($points / $checks->count()), 'critical_blockers_count' => $critical];
    }
}
