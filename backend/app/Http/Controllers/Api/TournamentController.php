<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\TournamentResource;
use App\Services\Tournament\TournamentReadService;

class TournamentController extends Controller
{
    public function __construct(
        private readonly TournamentReadService $tournamentReadService
    ) {}

    public function show(): TournamentResource
    {
        return new TournamentResource(
            $this->tournamentReadService->getSnapshot()
        );
    }
}
