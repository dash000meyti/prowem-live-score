<?php

namespace Database\Seeders;

use App\Enums\ReadinessStatus;
use Database\Seeders\Support\DemoEventBuilder;
use Illuminate\Database\Seeder;

class DemoMunichReadyCupSeeder extends Seeder
{
    public function run(DemoEventBuilder $builder): void
    {
        $data = $builder->event('MRC-2026', 'Munich Ready Cup 2026', 'ready', 8, 16, 2, 4, 14);
        $builder->standardDimensions($data['event']);
        foreach ($data['teams'] as $team) {
            $builder->teamChecks($data['event'], $team, array_fill_keys(['registration', 'payment', 'roster', 'eligibility', 'documents', 'check_in'], ReadinessStatus::Ready));
        }
    }
}
