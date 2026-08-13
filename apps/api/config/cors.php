<?php

return [

    'paths' => ['api/*', 'docs/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => array_values(array_filter([
        env('FRONTEND_URL', 'http://127.0.0.1:3000'),
        env('FRONTEND_URL_ALT', 'http://localhost:3000'),
    ])),

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,

];
