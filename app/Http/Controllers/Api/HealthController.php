<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        try {
            DB::select('select 1');
            Redis::ping();

            return ApiResponse::success(['status' => 'healthy'], 'Service is healthy.');
        } catch (\Throwable) {
            return ApiResponse::error('A dependency is unavailable.', 'SERVICE_UNHEALTHY', null, 503);
        }
    }
}
