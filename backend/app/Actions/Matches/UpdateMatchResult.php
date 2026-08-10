<?php

namespace App\Actions\Matches;

use App\Enums\GameStatus;
use App\Events\TournamentUpdated;
use App\Exceptions\InvalidGameStatusTransition;
use App\Exceptions\TeamAlreadyInLiveMatch;
use App\Models\Game;
use App\Models\Team;
use App\Services\Tournament\StandingsCalculator;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * @phpstan-import-type StandingRow from StandingsCalculator
 */
class UpdateMatchResult
{
    public function __construct(
        private readonly StandingsCalculator $standingsCalculator
    ) {}

    /**
     * @return array{
     *     update_id: string,
     *     occurred_at: string,
     *     game: Game,
     *     standings: Collection<int, StandingRow>
     * }
     */
    public function execute(
        Game $game,
        int $homeScore,
        int $awayScore,
        GameStatus $status
    ): array {
        $snapshot = DB::transaction(
            function () use (
                $game,
                $homeScore,
                $awayScore,
                $status
            ): array {
                /*
                 * The application currently owns one tournament.
                 *
                 * Locking all tournament teams provides one deterministic
                 * serialization point for result mutations. If multiple
                 * tournaments are introduced later, this lock should move
                 * to the owning tournament row.
                 */
                $teams = $this->lockTournamentTeams();

                $lockedGame = Game::query()
                    ->whereKey($game->getKey())
                    ->lockForUpdate()
                    ->firstOrFail();

                $this->assertTransitionAllowed(
                    current: $lockedGame->status,
                    next: $status
                );

                if ($status === GameStatus::InPlay) {
                    $this->assertTeamsAreAvailable($lockedGame);
                }

                $lockedGame->update([
                    'home_score' => $homeScore,
                    'away_score' => $awayScore,
                    'status' => $status,
                ]);

                $lockedGame->load([
                    'homeTeam',
                    'awayTeam',
                ]);

                /*
                 * Calculate standings before releasing the tournament lock
                 * so the match and standings belong to one logical snapshot.
                 */
                $games = Game::query()
                    ->orderBy('id')
                    ->get();

                $standings = $this->standingsCalculator->calculate(
                    $teams,
                    $games
                );

                return [
                    'game' => $lockedGame,
                    'standings' => $standings,
                ];
            },
            3
        );

        /*
         * Generate and broadcast only after the database transaction has
         * successfully committed.
         */
        $updateId = (string) Str::uuid();

        $occurredAt = now()
            ->utc()
            ->format('Y-m-d\TH:i:s.u\Z');

        $matchPayload = [
            'id' => $snapshot['game']->id,
            'round_number' => $snapshot['game']->round_number,
            'home_team_id' => $snapshot['game']->home_team_id,
            'away_team_id' => $snapshot['game']->away_team_id,
            'home_score' => $homeScore,
            'away_score' => $awayScore,
            'status' => $status->value,
            'kickoff_at' => $snapshot['game']->kickoff_at?->toISOString(),
        ];

        TournamentUpdated::dispatch(
            updateId: $updateId,
            occurredAt: $occurredAt,
            match: $matchPayload,
            standings: $snapshot['standings']->values()->all(),
        );

        return [
            'update_id' => $updateId,
            'occurred_at' => $occurredAt,
            'game' => $snapshot['game'],
            'standings' => $snapshot['standings'],
        ];
    }

    /**
     * @return Collection<int, Team>
     */
    private function lockTournamentTeams(): Collection
    {
        return Team::query()
            ->orderBy('id')
            ->lockForUpdate()
            ->get();
    }

    private function assertTeamsAreAvailable(
        Game $game
    ): void {
        $teamIds = [
            $game->home_team_id,
            $game->away_team_id,
        ];

        $conflictingGame = Game::query()
            ->where('id', '!=', $game->getKey())
            ->where(
                'status',
                GameStatus::InPlay->value
            )
            ->where(
                function ($query) use ($teamIds): void {
                    $query
                        ->whereIn(
                            'home_team_id',
                            $teamIds
                        )
                        ->orWhereIn(
                            'away_team_id',
                            $teamIds
                        );
                }
            )
            ->orderBy('id')
            ->first(['id']);

        if ($conflictingGame === null) {
            return;
        }

        throw new TeamAlreadyInLiveMatch(
            conflictingGameId: $conflictingGame->id
        );
    }

    private function assertTransitionAllowed(
        GameStatus $current,
        GameStatus $next
    ): void {
        if ($current->canTransitionTo($next)) {
            return;
        }

        throw new InvalidGameStatusTransition(
            sprintf(
                'Cannot transition a match from "%s" to "%s".',
                $current->value,
                $next->value
            )
        );
    }
}
