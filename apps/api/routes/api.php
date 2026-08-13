<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EventCareController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\IncidentController;
use App\Http\Controllers\Api\MobileController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ReadinessCheckController;
use App\Http\Controllers\Api\TeamOperationController;
use App\Http\Controllers\Api\TicketController;
use App\Http\Controllers\Api\TicketMessageController;
use Illuminate\Support\Facades\Route;

Route::get('/health', HealthController::class)->name('health');
Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:login');

Route::middleware(['auth:sanctum', 'throttle:api'])->group(function (): void {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/me', [MobileController::class, 'me']);
    Route::get('/events/summary', [MobileController::class, 'eventSummary']);
    Route::get('/events', [MobileController::class, 'events']);
    Route::get('/events/{event}/care', [EventCareController::class, 'overview']);
    Route::get('/events/{event}/lookups', [EventCareController::class, 'lookups']);
    Route::get('/events/{event}/readiness', [EventCareController::class, 'readiness']);
    Route::get('/events/{event}/teams/readiness', [EventCareController::class, 'teams']);
    Route::get('/events/{event}/teams/{team}/readiness', [EventCareController::class, 'team']);
    Route::patch('/events/{event}/status', [EventCareController::class, 'transition']);
    Route::get('/events/{event}/activity', [EventCareController::class, 'activity']);
    Route::get('/events/{event}/care-report', [EventCareController::class, 'report']);
    Route::get('/events/{event}/readiness/{dimension}', [MobileController::class, 'dimension']);
    Route::get('/events/{event}/live', [MobileController::class, 'live']);
    Route::post('/events/{event}/teams/{team}/actions/{operation}', TeamOperationController::class);
    Route::patch('/readiness-checks/{readinessCheck}', [ReadinessCheckController::class, 'update']);
    Route::get('/events/{event}/incidents', [IncidentController::class, 'index']);
    Route::post('/events/{event}/incidents', [IncidentController::class, 'store']);
    Route::get('/incidents/{incident}', [IncidentController::class, 'show']);
    Route::patch('/incidents/{incident}', [IncidentController::class, 'update']);
    Route::get('/events/{event}/tickets', [TicketController::class, 'index']);
    Route::get('/events/{event}/support-home', [TicketController::class, 'home']);
    Route::post('/events/{event}/tickets', [TicketController::class, 'store']);
    Route::get('/tickets/{ticket}', [TicketController::class, 'show']);
    Route::patch('/tickets/{ticket}', [TicketController::class, 'update']);
    Route::get('/tickets/{ticket}/messages', [TicketMessageController::class, 'index']);
    Route::post('/tickets/{ticket}/messages', [TicketMessageController::class, 'store']);
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'read']);
    Route::post('/notifications/read-all', [NotificationController::class, 'readAll']);
});
