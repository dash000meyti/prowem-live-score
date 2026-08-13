<?php

namespace App\Providers;

use App\Enums\ReadinessDimension;
use App\Enums\TeamOperation;
use App\Enums\UserRole;
use App\Exceptions\DomainRuleViolation;
use App\Models\User;
use App\OpenApi\OperationDocumentationTransformer;
use App\OpenApi\ProductSchemaDocumentTransformer;
use App\OpenApi\StandardErrorDocumentTransformer;
use Dedoc\Scramble\Scramble;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('api', fn (Request $request) => Limit::perMinute(120)->by((string) ($request->user()?->id ?? $request->ip())));
        RateLimiter::for('login', fn (Request $request) => Limit::perMinute(10)->by((string) $request->ip()));
        Gate::define('viewApiDocs', fn (?User $user) => config('app.public_api_docs') || $user?->role === UserRole::Admin);
        Route::bind('dimension', fn (string $value) => ReadinessDimension::tryFrom($value) ?? throw new DomainRuleViolation('INVALID_READINESS_DIMENSION', 'The requested readiness dimension is not supported.', 422));
        Route::bind('operation', fn (string $value) => TeamOperation::tryFrom($value) ?? throw new DomainRuleViolation('INVALID_TEAM_OPERATION', 'The requested team operation is not supported.', 422));
        Scramble::configure()->routes(fn ($route) => str_starts_with($route->uri(), 'api/v1'))->withDocumentTransformers([ProductSchemaDocumentTransformer::class, OperationDocumentationTransformer::class, StandardErrorDocumentTransformer::class]);
    }
}
