<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\StandingResource;
use App\Services\Tournament\TournamentReadService;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class StandingController extends Controller
{
    public function __construct(
        private readonly TournamentReadService $tournamentReadService
    ) {}

    public function index(): AnonymousResourceCollection
    {
        return StandingResource::collection(
            $this->tournamentReadService->getStandings()
        );
    }
}
