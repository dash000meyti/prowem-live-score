<?php

namespace App\Http\Controllers\Api;

use App\Actions\UpdateReadinessCheck;
use App\Enums\ReadinessStatus;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateReadinessRequest;
use App\Http\Resources\ReadinessCheckResource;
use App\Http\Responses\ApiResponse;
use App\Models\ReadinessCheck;
use Dedoc\Scramble\Attributes\Response;
use Illuminate\Http\JsonResponse;

class ReadinessCheckController extends Controller
{
    #[Response(type: 'array{success: true, message: string|null, data: \App\Http\Resources\ReadinessCheckResource}')]
    public function update(ReadinessCheck $readinessCheck, UpdateReadinessRequest $request, UpdateReadinessCheck $action): JsonResponse
    {
        if (! in_array($request->user()->role, [UserRole::SupportAgent, UserRole::SupportLead, UserRole::Admin], true)) {
            return ApiResponse::error('You are not authorized to perform this action.', 'FORBIDDEN', null, 403);
        }
        $this->authorize('view', $readinessCheck->event);
        $check = $action->execute($readinessCheck, ReadinessStatus::from($request->validated('status')), $request->validated('message'), $request->validated('reason'), $request->user());

        return ApiResponse::resource(new ReadinessCheckResource($check), 'Readiness check updated successfully.');
    }
}
