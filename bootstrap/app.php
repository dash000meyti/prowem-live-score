<?php

use App\Exceptions\DomainRuleViolation;
use App\Http\Middleware\AuthorizeBroadcastChannel;
use App\Http\Responses\ApiResponse;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(api: __DIR__.'/../routes/api.php', commands: __DIR__.'/../routes/console.php', health: '/up', apiPrefix: 'api/v1')
    ->withBroadcasting(__DIR__.'/../routes/channels.php', ['prefix' => 'api/v1', 'middleware' => ['api', 'auth:sanctum', AuthorizeBroadcastChannel::class]])
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->statefulApi();
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(fn (Request $request) => $request->is('api/*'));
        $exceptions->render(fn (ValidationException $e, Request $r) => $r->is('api/*') ? ApiResponse::error('The given data was invalid.', 'VALIDATION_FAILED', $e->errors(), 422) : null);
        $exceptions->render(fn (AuthenticationException $e, Request $r) => $r->is('api/*') ? ApiResponse::error('Unauthenticated.', 'UNAUTHENTICATED', null, 401) : null);
        $exceptions->render(fn (AuthorizationException $e, Request $r) => $r->is('api/*') ? ApiResponse::error('You are not authorized to perform this action.', 'FORBIDDEN', null, 403) : null);
        $exceptions->render(fn (DomainRuleViolation $e, Request $r) => $r->is('api/*') ? ApiResponse::error($e->getMessage(), $e->errorCode, $e->details, $e->httpStatus) : null);
        $exceptions->render(fn (ModelNotFoundException $e, Request $r) => $r->is('api/*') ? ApiResponse::error('Resource not found.', 'RESOURCE_NOT_FOUND', null, 404) : null);
        $exceptions->render(fn (TooManyRequestsHttpException $e, Request $r) => $r->is('api/*') ? ApiResponse::error('Too many requests.', 'RATE_LIMITED', null, 429) : null);
        $exceptions->render(fn (NotFoundHttpException $e, Request $r) => $r->is('api/*') ? ApiResponse::error('Resource not found.', 'RESOURCE_NOT_FOUND', null, 404) : null);
        $exceptions->render(fn (AccessDeniedHttpException $e, Request $r) => $r->is('api/*') ? ApiResponse::error('You are not authorized to perform this action.', 'FORBIDDEN', null, 403) : null);
        $exceptions->render(function (Throwable $e, Request $r) {
            if (! $r->is('api/*') || $e instanceof HttpExceptionInterface || $e instanceof ValidationException || $e instanceof AuthenticationException || $e instanceof AuthorizationException || $e instanceof DomainRuleViolation || $e instanceof ModelNotFoundException) {
                return null;
            }

            return ApiResponse::error('An unexpected error occurred.', 'INTERNAL_ERROR', null, 500);
        });
    })->create();
