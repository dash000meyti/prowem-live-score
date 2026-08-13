<?php

use App\OpenApi\StandardValidationErrorExtension;
use Dedoc\Scramble\SecurityDocumentation\MiddlewareAuthSecurityStrategy;

return [
    'api_path' => 'api/v1',
    'info' => [
        'version' => '1.0.0',
        'description' => 'PROWEM Event Care operational readiness and support API.',
    ],
    'ui' => ['title' => 'PROWEM Event Care API'],
    'renderer' => 'swagger',
    'renderers' => [
        'swagger' => [
            'view' => 'docs.swagger',
        ],
    ],
    'security_strategy' => MiddlewareAuthSecurityStrategy::class,
    'extensions' => [StandardValidationErrorExtension::class],
];
