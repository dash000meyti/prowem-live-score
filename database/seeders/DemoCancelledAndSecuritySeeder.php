<?php

namespace Database\Seeders;

use App\Models\Account;
use Database\Seeders\Support\DemoEventBuilder;
use Illuminate\Database\Seeder;

class DemoCancelledAndSecuritySeeder extends Seeder
{
    public function run(DemoEventBuilder $builder): void
    {
        $cancelled = $builder->event('GCC-2026', 'Graz Cancelled Cup', 'cancelled', 8, 12, 2, 4, 45);
        $builder->standardDimensions($cancelled['event']);

        $other = Account::query()->where('name', 'Other Football Club')->firstOrFail();
        $private = $builder->event('PRIVATE-2026', 'Private Club Cup', 'preparing', 8, 12, 2, 4, 21, $other);
        $builder->standardDimensions($private['event']);
    }
}
