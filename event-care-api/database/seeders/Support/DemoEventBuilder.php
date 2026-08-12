<?php

namespace Database\Seeders\Support;

use App\Enums\ReadinessStatus;
use App\Enums\ReadinessSubjectType;
use App\Models\Account;
use App\Models\Event;
use App\Models\Fixture;
use App\Models\ReadinessCheck;
use App\Models\Referee;
use App\Models\Team;
use App\Models\User;
use App\Models\Venue;
use App\Services\ReadinessCalculator;
use Carbon\CarbonImmutable;

final class DemoEventBuilder
{
    public function event(string $reference, string $name, string $status, int $teamCount, int $fixtureCount, int $fieldCount, int $refereeCount, int $dayOffset = 0, ?Account $account = null): array
    {
        $account ??= Account::query()->where('name', 'Vienna Football Association')->firstOrFail();
        $starts = CarbonImmutable::now()->startOfHour()->addDays($dayOffset);
        $event = Event::query()->create(['account_id' => $account->id, 'external_reference' => $reference, 'name' => $name, 'status' => $status, 'starts_at' => $starts, 'ends_at' => $starts->addHours(10), 'completed_at' => $status === 'completed' ? $starts->addHours(10) : null]);
        $organizer = User::query()->where('account_id', $account->id)->where('role', 'organizer')->firstOrFail();
        $support = User::query()->where('email', 'support@prowem.test')->first();
        $event->users()->attach($organizer->id, ['role' => 'organizer']);
        if ($support && $account->name === 'Vienna Football Association') {
            $event->users()->attach($support->id, ['role' => 'support_agent']);
        }

        $teams = collect(range(1, $teamCount))->map(fn (int $number) => Team::query()->create(['event_id' => $event->id, 'external_reference' => "{$reference}-TEAM-".str_pad((string) $number, 2, '0', STR_PAD_LEFT), 'name' => "{$name} Team {$number}"]));
        $venues = collect(range(1, $fieldCount))->map(fn (int $number) => Venue::query()->create(['event_id' => $event->id, 'name' => "Field {$number}"]));
        $referees = collect(range(1, $refereeCount))->map(fn (int $number) => Referee::query()->create(['event_id' => $event->id, 'name' => "Referee {$number}"]));
        $pairs = [];
        for ($home = 0; $home < $teamCount; $home++) {
            for ($away = $home + 1; $away < $teamCount; $away++) {
                $pairs[] = [$home, $away];
            }
        }
        for ($index = 0; $index < $fixtureCount; $index++) {
            [$home, $away] = $pairs[$index % count($pairs)];
            Fixture::query()->create(['event_id' => $event->id, 'venue_id' => $venues[$index % $fieldCount]->id, 'referee_id' => $refereeCount ? $referees[$index % $refereeCount]->id : null, 'home_team_id' => $teams[$home]->id, 'away_team_id' => $teams[$away]->id, 'number' => $index + 1, 'kickoff_at' => $starts->addMinutes($index * 20), 'status' => $status === 'cancelled' ? 'cancelled' : ($status === 'completed' ? 'completed' : 'scheduled'), 'delay_minutes' => 0]);
        }

        return compact('event', 'organizer', 'teams', 'venues', 'referees');
    }

    public function check(Event $event, string $dimension, string $type, ReadinessStatus $status = ReadinessStatus::Ready, bool $critical = false, ?Team $team = null, ?string $message = null, array $metadata = []): ReadinessCheck
    {
        return ReadinessCheck::query()->create(['event_id' => $event->id, 'subject_type' => $team ? ReadinessSubjectType::Team : (in_array($dimension, ['live_score', 'streaming', 'graphics'], true) ? ReadinessSubjectType::Service : ReadinessSubjectType::Event), 'subject_id' => $team?->id, 'dimension' => $dimension, 'check_type' => $type, 'status' => $status, 'is_critical' => $critical, 'message' => $message, 'metadata' => $metadata ?: null, 'last_checked_at' => now()]);
    }

    public function standardDimensions(Event $event, ReadinessStatus $status = ReadinessStatus::Ready): void
    {
        foreach (['teams', 'players', 'fixtures', 'referees', 'venues', 'staff', 'live_score', 'streaming', 'graphics'] as $dimension) {
            $this->check($event, $dimension, $dimension.'_ready', $status, in_array($dimension, ['venues', 'live_score', 'streaming'], true));
        }
    }

    public function teamChecks(Event $event, Team $team, array $statuses): void
    {
        foreach ($statuses as $type => $status) {
            $this->check($event, 'teams', $type, $status, in_array($type, ['payment', 'roster'], true), $team, $status === ReadinessStatus::Ready ? null : ucwords(str_replace('_', ' ', $type)).' requires attention.');
        }
        $this->recalculateTeam($event, $team);
    }

    public function recalculateTeam(Event $event, Team $team): void
    {
        $checks = ReadinessCheck::query()->where('event_id', $event->id)->where('subject_type', 'team')->where('subject_id', $team->id)->get();
        $result = app(ReadinessCalculator::class)->calculate($checks);
        $team->update(['readiness_status' => $result['status'], 'readiness_score' => $result['score']]);
    }
}
