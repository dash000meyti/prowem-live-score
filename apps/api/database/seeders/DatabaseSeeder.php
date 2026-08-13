<?php

namespace Database\Seeders;

use App\Events\EventCareChanged;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Event;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        Event::fake([EventCareChanged::class]);

        $this->call([
            DemoAccountsAndUsersSeeder::class,
            DemoViennaSummerCupSeeder::class,
            DemoAlpineYouthCupSeeder::class,
            DemoMunichReadyCupSeeder::class,
            DemoSalzburgOperationsCupSeeder::class,
            DemoZurichTechnicalCupSeeder::class,
            DemoSpringCupSeeder::class,
            DemoCancelledAndSecuritySeeder::class,
            DemoNotificationsSeeder::class,
        ]);
    }
}
