<?php

namespace App\Http\Controllers\Api;

use App\Actions\Matches\UpdateMatchResult;
use App\Enums\GameStatus;
use App\Exceptions\InvalidGameStatusTransition;
use App\Exceptions\TeamAlreadyInLiveMatch;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateMatchResultRequest;
use App\Http\Resources\GameResource;
use App\Http\Resources\MatchUpdateResource;
use App\Models\Game;
use App\Services\Tournament\TournamentReadService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class MatchController extends Controller
{
    public function __construct(
        private readonly TournamentReadService $tournamentReadService,
        private readonly UpdateMatchResult $updateMatchResult
    ) {}

    public function index(): AnonymousResourceCollection
    {
        return GameResource::collection(
            $this->tournamentReadService->listMatches()
        );
    }

    public function updateResult(
        Game $game,
        UpdateMatchResultRequest $request
    ): MatchUpdateResource|JsonResponse {
        $validated = $request->validated();

        try {
            $result = $this->updateMatchResult->execute(
                game: $game,
                homeScore: $validated['home_score'],
                awayScore: $validated['away_score'],
                status: GameStatus::from($validated['status']),
            );
        } catch (InvalidGameStatusTransition $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
                'code' => InvalidGameStatusTransition::CODE,
                'errors' => [
                    'status' => [
                        $exception->getMessage(),
                    ],
                ],
            ], 409);
        } catch (TeamAlreadyInLiveMatch $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
                'code' => TeamAlreadyInLiveMatch::CODE,
                'errors' => [
                    'status' => [
                        $exception->getMessage(),
                    ],
                ],
                'conflict' => [
                    'match_id' => $exception->conflictingGameId,
                ],
            ], 409);
        }

        return new MatchUpdateResource($result);
    }
}
