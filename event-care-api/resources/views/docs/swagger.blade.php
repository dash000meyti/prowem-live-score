<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $config->get('ui.title') ?? config('app.name').' - API Docs' }}</title>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
    <link rel="icon" type="image/png" href="https://unpkg.com/swagger-ui-dist@5/favicon-32x32.png">
    <style>
        html { box-sizing: border-box; overflow-y: scroll; }
        *, *::before, *::after { box-sizing: inherit; }
        body { margin: 0; background: #fafafa; }
        .swagger-ui .topbar { background: #172554; padding: 12px 0; }
        .swagger-ui .topbar-wrapper::before {
            color: #fff;
            content: "PROWEM Event Care";
            font: 600 20px system-ui, sans-serif;
        }
        .swagger-ui .topbar-wrapper img,
        .swagger-ui .topbar-wrapper .link span { display: none; }
        .swagger-ui .info .title { color: #172554; }
        .swagger-ui .opblock.opblock-get { border-color: #2563eb; background: rgba(37, 99, 235, .08); }
        .swagger-ui .opblock.opblock-post { border-color: #16a34a; background: rgba(22, 163, 74, .08); }
        .swagger-ui .opblock.opblock-patch { border-color: #d97706; background: rgba(217, 119, 6, .08); }
    </style>
</head>
<body>
<div id="swagger-ui"></div>
<script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
<script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
<script>
    window.onload = () => SwaggerUIBundle({
        spec: @json($spec),
        dom_id: '#swagger-ui',
        deepLinking: true,
        persistAuthorization: true,
        displayRequestDuration: true,
        filter: true,
        docExpansion: 'list',
        defaultModelsExpandDepth: 1,
        presets: [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset],
        layout: 'StandaloneLayout',
        requestInterceptor: request => {
            request.credentials = 'include';
            return request;
        }
    });
</script>
</body>
</html>
