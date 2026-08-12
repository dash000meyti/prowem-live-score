<?php

namespace App\Http\Responses;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\JsonResource;

final class ApiResponse
{
    public static function success(mixed $data, ?string $message = null, int $status = 200): JsonResponse
    {
        return response()->json(['success' => true, 'message' => $message, 'data' => $data], $status);
    }

    public static function resource(JsonResource $resource, ?string $message = null, int $status = 200): JsonResponse
    {
        return self::success($resource->resolve(request()), $message, $status);
    }

    public static function paginated(LengthAwarePaginator $paginator, string $resource, ?string $message = null): JsonResponse
    {
        $items = $resource::collection($paginator->getCollection())->resolve(request());

        return response()->json(['success' => true, 'message' => $message, 'data' => $items, 'meta' => ['pagination' => ['current_page' => $paginator->currentPage(), 'per_page' => $paginator->perPage(), 'total' => $paginator->total(), 'last_page' => $paginator->lastPage(), 'from' => $paginator->firstItem(), 'to' => $paginator->lastItem()]], 'links' => ['first' => $paginator->url(1), 'last' => $paginator->url($paginator->lastPage()), 'prev' => $paginator->previousPageUrl(), 'next' => $paginator->nextPageUrl()]]);
    }

    public static function error(string $message, string $code, mixed $details = null, int $status = 400): JsonResponse
    {
        return response()->json(['success' => false, 'message' => $message, 'error' => ['code' => $code, 'details' => $details]], $status);
    }
}
