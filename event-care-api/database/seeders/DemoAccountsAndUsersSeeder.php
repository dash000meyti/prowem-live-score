<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Models\Account;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DemoAccountsAndUsersSeeder extends Seeder
{
    public function run(): void
    {
        $primary = Account::query()->create(['name' => 'Vienna Football Association', 'plan' => 'premium']);
        $other = Account::query()->create(['name' => 'Other Football Club', 'plan' => 'standard']);

        foreach ([
            ['account_id' => $primary->id, 'name' => 'Olivia Organizer', 'email' => 'organizer@prowem.test', 'role' => UserRole::Organizer],
            ['account_id' => null, 'name' => 'Sam Support', 'email' => 'support@prowem.test', 'role' => UserRole::SupportAgent],
            ['account_id' => null, 'name' => 'PROWEM Support Lead', 'email' => 'lead@prowem.test', 'role' => UserRole::SupportLead],
            ['account_id' => null, 'name' => 'PROWEM Admin', 'email' => 'admin@prowem.test', 'role' => UserRole::Admin],
            ['account_id' => $other->id, 'name' => 'Oscar Other Organizer', 'email' => 'other-organizer@prowem.test', 'role' => UserRole::Organizer],
        ] as $user) {
            User::query()->create([...$user, 'password' => Hash::make('password')]);
        }
    }
}
