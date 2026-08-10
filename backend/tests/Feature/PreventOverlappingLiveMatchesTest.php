<?php

namespace Tests\Feature;

use App\Events\TournamentUpdated;
use App\Models\Game;
use App\Models\Team;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class PreventOverlappingLiveMatchesTest extends TestCase
{
    use RefreshDatabase;

    public function test_team_cannot_participate_in_two_live_matches(): void
    {
        Event::fake([
            TournamentUpdated::class,
        ]);

        $juventus = Team::query()->create(['name' => 'Juventus']);
        $inter = Team::query()->create(['name' => 'Inter']);
        $milan = Team::query()->create(['name' => 'AC Milan']);

        $liveGame = $this->createGame(
            homeTeam: $inter,
            awayTeam: $milan,
            round: 1,
            status: 'in_play',
            homeScore: 1,
            awayScore: 2,
        );

        $candidate = $this->createGame(
            homeTeam: $milan,
            awayTeam: $juventus,
            round: 2,
        );

        $response = $this->patchJson(
            route('matches.result.update', $candidate),
            [
                'home_score' => 0,
                'away_score' => 0,
                'status' => 'in_play',
            ]
        );

        $response
            ->assertStatus(409)
            ->assertJsonPath(
                'message',
                'One of the teams is already playing another live match.'
            )
            ->assertJsonPath(
                'conflict.match_id',
                $liveGame->id
            );

        $candidate->refresh();

        $this->assertSame('scheduled', $candidate->status->value);
        $this->assertNull($candidate->home_score);
        $this->assertNull($candidate->away_score);

        Event::assertNotDispatched(TournamentUpdated::class);
    }

    public function test_two_disjoint_matches_may_be_live_at_the_same_time(): void
    {
        $juventus = Team::query()->create(['name' => 'Juventus']);
        $inter = Team::query()->create(['name' => 'Inter']);
        $milan = Team::query()->create(['name' => 'AC Milan']);
        $roma = Team::query()->create(['name' => 'AS Roma']);

        $this->createGame(
            homeTeam: $juventus,
            awayTeam: $roma,
            round: 1,
            status: 'in_play',
            homeScore: 1,
            awayScore: 0,
        );

        $candidate = $this->createGame(
            homeTeam: $inter,
            awayTeam: $milan,
            round: 1,
        );

        $response = $this->patchJson(
            route('matches.result.update', $candidate),
            [
                'home_score' => 0,
                'away_score' => 0,
                'status' => 'in_play',
            ]
        );

        $response->assertOk();

        $candidate->refresh();

        $this->assertSame('in_play', $candidate->status->value);
        $this->assertSame(0, $candidate->home_score);
        $this->assertSame(0, $candidate->away_score);
    }

    public function test_live_match_can_receive_score_updates_when_there_is_no_conflict(): void
    {
        $juventus = Team::query()->create(['name' => 'Juventus']);
        $roma = Team::query()->create(['name' => 'AS Roma']);

        $game = $this->createGame(
            homeTeam: $juventus,
            awayTeam: $roma,
            round: 1,
            status: 'in_play',
            homeScore: 0,
            awayScore: 0,
        );

        $response = $this->patchJson(
            route('matches.result.update', $game),
            [
                'home_score' => 1,
                'away_score' => 0,
                'status' => 'in_play',
            ]
        );

        $response->assertOk();

        $game->refresh();

        $this->assertSame('in_play', $game->status->value);
        $this->assertSame(1, $game->home_score);
        $this->assertSame(0, $game->away_score);
    }

    public function test_existing_invalid_overlap_can_be_recovered_by_finishing_one_match(): void
    {
        $juventus = Team::query()->create(['name' => 'Juventus']);
        $inter = Team::query()->create(['name' => 'Inter']);
        $milan = Team::query()->create(['name' => 'AC Milan']);

        $this->createGame(
            homeTeam: $inter,
            awayTeam: $milan,
            round: 1,
            status: 'in_play',
            homeScore: 1,
            awayScore: 2,
        );

        $secondLiveGame = $this->createGame(
            homeTeam: $milan,
            awayTeam: $juventus,
            round: 2,
            status: 'in_play',
            homeScore: 0,
            awayScore: 0,
        );

        $response = $this->patchJson(
            route('matches.result.update', $secondLiveGame),
            [
                'home_score' => 0,
                'away_score' => 0,
                'status' => 'finished',
            ]
        );

        $response->assertOk();

        $secondLiveGame->refresh();

        $this->assertSame('finished', $secondLiveGame->status->value);
    }

    private function createGame(
        Team $homeTeam,
        Team $awayTeam,
        int $round,
        string $status = 'scheduled',
        ?int $homeScore = null,
        ?int $awayScore = null,
    ): Game {
        return Game::query()->create([
            'home_team_id' => $homeTeam->id,
            'away_team_id' => $awayTeam->id,
            'round_number' => $round,
            'home_score' => $homeScore,
            'away_score' => $awayScore,
            'status' => $status,
            'kickoff_at' => null,
        ]);
    }
}
