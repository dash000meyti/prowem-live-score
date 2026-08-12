<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use App\Http\Responses\ApiResponse;
use App\Models\Event;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AuthorizeBroadcastChannel
{
    public function handle(Request $request, Closure $next): Response
    {
        if (preg_match('/^private-events\.(\d+)$/', (string) $request->input('channel_name'), $matches)) {
            $event = Event::query()->find((int) $matches[1]);
            $user = $request->user();
            if (! ($event && $user && (in_array($user->role, [UserRole::SupportAgent, UserRole::SupportLead, UserRole::Admin], true) || $user->account_id === $event->account_id))) {
                return ApiResponse::error('You are not authorized to subscribe to this channel.', 'FORBIDDEN', null, 403);
            }
        }

        return $next($request);
    }
}
