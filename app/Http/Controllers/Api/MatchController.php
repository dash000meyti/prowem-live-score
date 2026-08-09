<?php

namespace App\Http\Controllers\Api;

use App\Actions\Matches\UpdateMatchResult;
use App\Enums\GameStatus;
use App\Exceptions\InvalidGameStatusTransition;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateMatchResultRequest;
use App\Models\Game;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

class MatchController extends Controller
{
    public function updateResult(
        Game $game,
        UpdateMatchResultRequest $request,
        UpdateMatchResult $action
    ): JsonResponse {
        $validated = $request->validated();

        try {
            $result = $action->execute(
                game: $game,
                homeScore: $validated['home_score'],
                awayScore: $validated['away_score'],
                status: GameStatus::from($validated['status']),
            );
        } catch (InvalidGameStatusTransition $exception) {
            throw ValidationException::withMessages([
                'status' => [
                    $exception->getMessage(),
                ],
            ]);
        }

        return response()->json([
            'data' => [
                'match' => [
                    'id' => $result['game']->id,
                    'round_number' => $result['game']->round_number,
                    'home_team_id' => $result['game']->home_team_id,
                    'away_team_id' => $result['game']->away_team_id,
                    'home_score' => $result['game']->home_score,
                    'away_score' => $result['game']->away_score,
                    'status' => $result['game']->status->value,
                    'kickoff_at' => $result['game']->kickoff_at,
                ],

                'standings' => $result['standings']->values(),
            ],
        ]);
    }
}
