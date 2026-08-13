<?php

namespace App\Services;

use App\Enums\TicketPriority;
use Carbon\CarbonImmutable;

final class SlaCalculator
{
    public function responseDeadline(TicketPriority $priority, string $plan, bool $live, ?CarbonImmutable $from = null): CarbonImmutable
    {
        $minutes = match ($priority) {
            TicketPriority::P1 => 15,TicketPriority::P2 => 60,TicketPriority::P3 => 240,TicketPriority::P4 => 480
        };
        if ($live) {
            $minutes = (int) max(5, round($minutes * .5));
        }
        if ($plan === 'premium') {
            $minutes = (int) max(5, round($minutes * .75));
        }

        return ($from ?? CarbonImmutable::now())->addMinutes($minutes);
    }

    public function state(?\DateTimeInterface $respondedAt, \DateTimeInterface $dueAt): string
    {
        if ($respondedAt) {
            return $respondedAt <= $dueAt ? 'met' : 'breached';
        } if (now()->greaterThan($dueAt)) {
            return 'breached';
        }

        return now()->diffInMinutes($dueAt) <= 15 ? 'approaching' : 'on_track';
    }
}
