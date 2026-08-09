<?php

use App\Http\Controllers\Api\MatchController;
use Illuminate\Support\Facades\Route;

Route::patch(
    '/matches/{game}/result',
    [MatchController::class, 'updateResult']
)->name('matches.result.update');
