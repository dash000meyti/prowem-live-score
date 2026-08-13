<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Responses\ApiResponse;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::query()->where('email', $request->string('email'))->first();
        if (! $user || ! Hash::check($request->string('password'), $user->password)) {
            return ApiResponse::error('The provided credentials are invalid.', 'INVALID_CREDENTIALS', null, 401);
        }$token = $user->createToken($request->string('device_name', 'api'))->plainTextToken;

        return ApiResponse::success(['token' => $token, 'token_type' => 'Bearer', 'user' => ['id' => $user->id, 'name' => $user->name, 'email' => $user->email, 'role' => $user->role->value]], 'Authenticated successfully.');
    }

    public function logout(): JsonResponse
    {
        request()->user()?->currentAccessToken()?->delete();

        return ApiResponse::success(null, 'Logged out successfully.');
    }
}
