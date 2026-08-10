<?php

namespace App\Events;

use App\Services\Tournament\StandingsCalculator;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * @phpstan-import-type StandingRow from StandingsCalculator
 *
 * @phpstan-type MatchPayload array{
 *     id: int,
 *     round_number: int,
 *     home_team_id: int,
 *     away_team_id: int,
 *     home_score: int,
 *     away_score: int,
 *     status: string,
 *     kickoff_at: string|null
 * }
 */
class TournamentUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets;

    /**
     * @param  MatchPayload  $match
     * @param  array<int, StandingRow>  $standings
     */
    public function __construct(
        public readonly string $updateId,
        public readonly string $occurredAt,
        public readonly array $match,
        public readonly array $standings,
    ) {}

    public function broadcastOn(): array
    {
        return [
            new Channel('tournament'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'tournament.updated';
    }

    /**
     * @return array{
     *     update_id: string,
     *     occurred_at: string,
     *     match: MatchPayload,
     *     standings: array<int, StandingRow>
     * }
     */
    public function broadcastWith(): array
    {
        return [
            'update_id' => $this->updateId,
            'occurred_at' => $this->occurredAt,
            'match' => $this->match,
            'standings' => $this->standings,
        ];
    }
}
