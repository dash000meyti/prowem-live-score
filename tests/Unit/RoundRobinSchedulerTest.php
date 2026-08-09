<?php

namespace Tests\Unit;

use App\Models\Team;
use App\Services\Tournament\RoundRobinScheduler;
use Illuminate\Support\Collection;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

class RoundRobinSchedulerTest extends TestCase
{
    private RoundRobinScheduler $scheduler;

    protected function setUp(): void
    {
        parent::setUp();

        $this->scheduler = new RoundRobinScheduler();
    }

    public function test_it_generates_six_matches_for_four_teams(): void
    {
        $fixtures = $this->scheduler->generate($this->teams());

        $this->assertCount(6, $fixtures);
    }

    public function test_it_generates_three_rounds_with_two_matches_each(): void
    {
        $fixtures = collect(
            $this->scheduler->generate($this->teams())
        );

        $rounds = $fixtures->groupBy('round_number');

        $this->assertCount(3, $rounds);

        foreach ($rounds as $matches) {
            $this->assertCount(2, $matches);
        }
    }

    public function test_no_team_plays_itself(): void
    {
        $fixtures = $this->scheduler->generate($this->teams());

        foreach ($fixtures as $fixture) {
            $this->assertNotSame(
                $fixture['home_team_id'],
                $fixture['away_team_id']
            );
        }
    }

    public function test_each_pair_appears_exactly_once(): void
    {
        $fixtures = collect(
            $this->scheduler->generate($this->teams())
        );

        $pairs = $fixtures
            ->map(fn (array $fixture) => $this->pairKey(
                $fixture['home_team_id'],
                $fixture['away_team_id']
            ));

        $this->assertCount(6, $pairs);
        $this->assertCount(6, $pairs->unique());

        $this->assertEqualsCanonicalizing(
            [
                '1-2',
                '1-3',
                '1-4',
                '2-3',
                '2-4',
                '3-4',
            ],
            $pairs->all()
        );
    }

    public function test_each_team_plays_once_per_round(): void
    {
        $fixtures = collect(
            $this->scheduler->generate($this->teams())
        );

        foreach ($fixtures->groupBy('round_number') as $round) {
            $teamIds = $round
                ->flatMap(fn (array $fixture) => [
                    $fixture['home_team_id'],
                    $fixture['away_team_id'],
                ]);

            $this->assertCount(4, $teamIds);
            $this->assertCount(4, $teamIds->unique());
        }
    }

    public function test_each_team_plays_every_other_team_once(): void
    {
        $fixtures = collect(
            $this->scheduler->generate($this->teams())
        );

        foreach ($this->teams() as $team) {
            $opponents = $fixtures
                ->filter(
                    fn (array $fixture) =>
                        $fixture['home_team_id'] === $team->id
                        || $fixture['away_team_id'] === $team->id
                )
                ->map(
                    fn (array $fixture) =>
                    $fixture['home_team_id'] === $team->id
                        ? $fixture['away_team_id']
                        : $fixture['home_team_id']
                );

            $this->assertCount(3, $opponents);
            $this->assertCount(3, $opponents->unique());
            $this->assertNotContains(
                $team->id,
                $opponents->all()
            );
        }
    }

    public function test_home_and_away_distribution_is_balanced(): void
    {
        $fixtures = collect(
            $this->scheduler->generate($this->teams())
        );

        foreach ($this->teams() as $team) {
            $homeMatches = $fixtures
                ->where('home_team_id', $team->id)
                ->count();

            $awayMatches = $fixtures
                ->where('away_team_id', $team->id)
                ->count();

            $this->assertSame(3, $homeMatches + $awayMatches);

            $this->assertLessThanOrEqual(
                1,
                abs($homeMatches - $awayMatches)
            );
        }
    }

    public function test_it_supports_an_odd_number_of_teams_with_a_bye(): void
    {
        $teams = $this->teams(5);

        $fixtures = collect(
            $this->scheduler->generate($teams)
        );

        // 5 × 4 / 2
        $this->assertCount(10, $fixtures);

        $rounds = $fixtures->groupBy('round_number');

        $this->assertCount(5, $rounds);

        foreach ($rounds as $round) {
            $this->assertCount(2, $round);

            $teamIds = $round->flatMap(
                fn (array $fixture) => [
                    $fixture['home_team_id'],
                    $fixture['away_team_id'],
                ]
            );

            // Four teams play, one team has a bye.
            $this->assertCount(4, $teamIds);
            $this->assertCount(4, $teamIds->unique());
        }
    }

    public function test_it_rejects_less_than_two_teams(): void
    {
        $this->expectException(InvalidArgumentException::class);

        $this->scheduler->generate(collect([
            $this->team(1),
        ]));
    }

    private function teams(int $count = 4): Collection
    {
        return collect(range(1, $count))
            ->map(
                fn (int $id) => $this->team($id)
            );
    }

    private function team(int $id): Team
    {
        $team = new Team([
            'name' => "Team {$id}",
        ]);

        $team->id = $id;

        return $team;
    }

    private function pairKey(int $firstTeamId, int $secondTeamId): string
    {
        $ids = [$firstTeamId, $secondTeamId];

        sort($ids);

        return implode('-', $ids);
    }
}
