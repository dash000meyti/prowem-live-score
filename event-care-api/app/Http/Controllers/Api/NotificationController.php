<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Http\Responses\ApiResponse;
use Dedoc\Scramble\Attributes\Response;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Notifications\DatabaseNotification;

class NotificationController extends Controller
{
    #[Response(type: 'array{success: true, message: string|null, data: list<\App\Http\Resources\NotificationResource>, meta: array{pagination: array{current_page:int,per_page:int,total:int,last_page:int,from:int|null,to:int|null}}, links: array{first:string,last:string,prev:string|null,next:string|null}}')]
    public function index(Request $request): JsonResponse
    {
        $request->validate(['page' => ['sometimes', 'integer', 'min:1'], 'per_page' => ['sometimes', 'integer', 'min:1', 'max:100']]);
        $per = min(max((int) $request->input('per_page', 20), 1), 100);

        return ApiResponse::paginated($request->user()->notifications()->latest()->paginate($per)->withQueryString(), NotificationResource::class, 'Notifications retrieved successfully.');
    }

    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\NotificationResource}')]
    public function read(DatabaseNotification $notification, Request $request): JsonResponse
    {
        abort_unless($notification->notifiable_id === $request->user()->id && $notification->notifiable_type === $request->user()::class, 404);
        $notification->markAsRead();

        return ApiResponse::resource(new NotificationResource($notification), 'Notification marked as read.');
    }

    public function readAll(Request $request): JsonResponse
    {
        $request->user()->unreadNotifications()->update(['read_at' => now()]);

        return ApiResponse::success(null, 'All notifications marked as read.');
    }
}
