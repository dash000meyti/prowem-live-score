<?php

use App\Http\Controllers\Api\MatchController;
use App\Http\Controllers\Api\StandingController;
use App\Http\Controllers\Api\TournamentController;
use Illuminate\Support\Facades\Route;

Route::get(
    '/tournament',
    [TournamentController::class, 'show']
)->name('tournament.show');

Route::get(
    '/matches',
    [MatchController::class, 'index']
)->name('matches.index');

Route::get(
    '/standings',
    [StandingController::class, 'index']
)->name('standings.index');

Route::patch(
    '/matches/{game}/result',
    [MatchController::class, 'updateResult']
)->name('matches.result.update');
