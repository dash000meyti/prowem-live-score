<?php

namespace Database\Seeders;

use App\Enums\ReadinessStatus;
use Database\Seeders\Support\DemoEventBuilder;
use Illuminate\Database\Seeder;

class DemoAlpineYouthCupSeeder extends Seeder
{
    public function run(DemoEventBuilder $builder): void
    {
        $data = $builder->event('ALP-2026', 'Alpine Youth Cup 2026', 'preparing', 12, 24, 3, 6, 30);
        $event = $data['event'];
        $data['teams'][0]->update(['name' => 'Salzburg United', 'manager_name' => 'Martin Berger', 'manager_phone' => '+43 660 123456']);
        $data['teams'][1]->update(['name' => 'Alpine Juniors B']);
        $builder->teamChecks($event, $data['teams'][0], ['registration' => ReadinessStatus::Ready, 'payment' => ReadinessStatus::Blocked, 'roster' => ReadinessStatus::Ready, 'eligibility' => ReadinessStatus::Ready, 'documents' => ReadinessStatus::Ready, 'check_in' => ReadinessStatus::Warning]);
        $builder->teamChecks($event, $data['teams'][1], ['registration' => ReadinessStatus::Ready, 'payment' => ReadinessStatus::Ready, 'roster' => ReadinessStatus::Blocked, 'eligibility' => ReadinessStatus::Ready, 'documents' => ReadinessStatus::Warning, 'check_in' => ReadinessStatus::Ready]);
        foreach (['players', 'fixtures', 'venues', 'staff', 'live_score', 'graphics'] as $dimension) {
            $builder->check($event, $dimension, $dimension.'_ready');
        }
        $builder->check($event, 'referees', 'referee_confirmation', ReadinessStatus::Warning, false, null, 'One referee has not confirmed.', ['label' => 'Referee 6', 'action' => 'confirm_referee']);
        $builder->check($event, 'streaming', 'streaming_test_field_2', ReadinessStatus::Blocked, true, null, 'Field 2 pre-event streaming test failed.', ['label' => 'Field 2', 'action' => 'rerun_streaming_test']);
    }
}
