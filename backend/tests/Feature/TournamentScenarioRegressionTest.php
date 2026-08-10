<?php

namespace Tests\Feature;

use App\Events\TournamentUpdated;
use App\Models\Game;
use App\Models\Team;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class TournamentScenarioRegressionTest extends TestCase
{
    use RefreshDatabase;

    public function test_starting_zero_zero_is_a_real_played_draw_not_an_unplayed_match(): void
    {
        Event::fake([TournamentUpdated::class]);

        [$juventus, $roma] = $this->createTeams('Juventus', 'AS Roma');

        $game = $this->createGame(
            homeTeam: $juventus,
            awayTeam: $roma,
            status: 'scheduled',
        );

        $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => 0,
                'away_score' => 0,
                'status' => 'in_play',
            ]
        )->assertOk();

        $game->refresh();

        $this->assertSame('in_play', $game->status->value);
        $this->assertSame(0, $game->home_score);
        $this->assertSame(0, $game->away_score);

        $standings = $this->getJson(
            route('standings.index')
        )->assertOk()->json('data');

        $juventusStanding = $this->standingFor(
            standings: $standings,
            teamId: $juventus->id,
        );

        $romaStanding = $this->standingFor(
            standings: $standings,
            teamId: $roma->id,
        );

        $this->assertSame(1, $juventusStanding['played']);
        $this->assertSame(1, $juventusStanding['drawn']);
        $this->assertSame(1, $juventusStanding['points']);

        $this->assertSame(1, $romaStanding['played']);
        $this->assertSame(1, $romaStanding['drawn']);
        $this->assertSame(1, $romaStanding['points']);
    }

    public function test_live_result_correction_recalculates_standings_and_remains_live(): void
    {
        Event::fake([TournamentUpdated::class]);

        [$milan, $inter] = $this->createTeams('AC Milan', 'Inter');

        $game = $this->createGame(
            homeTeam: $milan,
            awayTeam: $inter,
            status: 'in_play',
            homeScore: 2,
            awayScore: 1,
        );

        $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => 1,
                'away_score' => 1,
                'status' => 'in_play',
            ]
        )->assertOk();

        $game->refresh();

        $this->assertSame('in_play', $game->status->value);
        $this->assertSame(1, $game->home_score);
        $this->assertSame(1, $game->away_score);

        $standings = $this->getJson(
            route('standings.index')
        )->assertOk()->json('data');

        $milanStanding = $this->standingFor(
            standings: $standings,
            teamId: $milan->id,
        );

        $interStanding = $this->standingFor(
            standings: $standings,
            teamId: $inter->id,
        );

        $this->assertSame(1, $milanStanding['played']);
        $this->assertSame(1, $milanStanding['drawn']);
        $this->assertSame(1, $milanStanding['points']);
        $this->assertSame(0, $milanStanding['goal_difference']);

        $this->assertSame(1, $interStanding['played']);
        $this->assertSame(1, $interStanding['drawn']);
        $this->assertSame(1, $interStanding['points']);
        $this->assertSame(0, $interStanding['goal_difference']);
    }

    public function test_finished_result_correction_recalculates_standings_and_stays_finished(): void
    {
        Event::fake([TournamentUpdated::class]);

        [$juventus, $roma] = $this->createTeams('Juventus', 'AS Roma');

        $game = $this->createGame(
            homeTeam: $juventus,
            awayTeam: $roma,
            status: 'finished',
            homeScore: 2,
            awayScore: 0,
        );

        $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => 1,
                'away_score' => 1,
                'status' => 'finished',
            ]
        )->assertOk();

        $game->refresh();

        $this->assertSame('finished', $game->status->value);
        $this->assertSame(1, $game->home_score);
        $this->assertSame(1, $game->away_score);

        $standings = $this->getJson(
            route('standings.index')
        )->assertOk()->json('data');

        $juventusStanding = $this->standingFor(
            standings: $standings,
            teamId: $juventus->id,
        );

        $romaStanding = $this->standingFor(
            standings: $standings,
            teamId: $roma->id,
        );

        $this->assertSame(1, $juventusStanding['points']);
        $this->assertSame(1, $romaStanding['points']);
        $this->assertSame(0, $juventusStanding['goal_difference']);
        $this->assertSame(0, $romaStanding['goal_difference']);
    }

    /**
     * @return array{0: Team, 1: Team}
     */
    private function createTeams(
        string $firstName,
        string $secondName
    ): array {
        return [
            Team::query()->create([
                'name' => $firstName,
            ]),
            Team::query()->create([
                'name' => $secondName,
            ]),
        ];
    }

    private function createGame(
        Team $homeTeam,
        Team $awayTeam,
        string $status,
        ?int $homeScore = null,
        ?int $awayScore = null,
    ): Game {
        return Game::query()->create([
            'home_team_id' => $homeTeam->id,
            'away_team_id' => $awayTeam->id,
            'round_number' => 1,
            'home_score' => $homeScore,
            'away_score' => $awayScore,
            'status' => $status,
            'kickoff_at' => null,
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $standings
     * @return array<string, mixed>
     */
    private function standingFor(
        array $standings,
        int $teamId
    ): array {
        foreach ($standings as $standing) {
            if ((int) $standing['team_id'] === $teamId) {
                return $standing;
            }
        }

        $this->fail(
            sprintf(
                'Standing row for team %d was not found.',
                $teamId
            )
        );
    }
}
