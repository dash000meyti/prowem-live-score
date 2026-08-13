<?php

namespace App\OpenApi;

use Dedoc\Scramble\Contracts\DocumentTransformer;
use Dedoc\Scramble\OpenApiContext;
use Dedoc\Scramble\Support\Generator\OpenApi;
use Dedoc\Scramble\Support\Generator\Reference;
use Dedoc\Scramble\Support\Generator\Response;
use Dedoc\Scramble\Support\Generator\Schema;
use Dedoc\Scramble\Support\Generator\Types;

class StandardErrorDocumentTransformer implements DocumentTransformer
{
    public function handle(OpenApi $document, OpenApiContext $context): void
    {
        $details = (new Types\MixedType)->nullable(true)->setDescription('Null, scalar, object, or array depending on the error code.');
        $error = (new Types\ObjectType)->addProperty('code', new Types\StringType)->addProperty('details', $details)->setRequired(['code', 'details']);
        $body = (new Types\ObjectType)->addProperty('success', (new Types\BooleanType)->example(false))->addProperty('message', new Types\StringType)->addProperty('error', $error)->setRequired(['success', 'message', 'error']);
        $ref = $document->components->addSchema('ApiError', Schema::fromType($body));
        foreach ($document->paths as $path) {
            $publicPath = '/'.ltrim((string) preg_replace('#^/?api/v1#', '', $path->path), '/');
            foreach ($path->operations as $operation) {
                if ($publicPath === '/health') {
                    $operation->security = [];
                    $this->removeResponses($operation->responses, [401, 403, 429]);
                    $operation->addResponse(Response::make(500)->setDescription('Unexpected server error')->setContent('application/json', $ref));
                } elseif ($publicPath === '/auth/login') {
                    $operation->security = [];
                    $this->removeResponses($operation->responses, [403]);
                    foreach ([401 => 'Invalid credentials', 429 => 'Rate limited', 500 => 'Unexpected server error'] as $code => $description) {
                        $operation->addResponse(Response::make($code)->setDescription($description)->setContent('application/json', $ref));
                    }
                } else {
                    foreach ([401 => 'Unauthenticated', 403 => 'Forbidden', 429 => 'Rate limited', 500 => 'Unexpected server error'] as $code => $description) {
                        $operation->addResponse(Response::make($code)->setDescription($description)->setContent('application/json', $ref));
                    }
                }

                if (str_contains($publicPath, '{')) {
                    $operation->addResponse(Response::make(404)->setDescription('Resource not found')->setContent('application/json', $ref));
                }

                if (in_array(strtolower($operation->method), ['post', 'patch'], true) && (str_contains($publicPath, '/status') || str_contains($publicPath, '/incidents') || str_contains($publicPath, '/tickets'))) {
                    $operation->addResponse(Response::make(409)->setDescription('Domain conflict')->setContent('application/json', $ref));
                }
            }
        }

        foreach (['AuthenticationException', 'AuthorizationException', 'ModelNotFoundException'] as $legacy) {
            if ($document->components->hasSchema($legacy)) {
                $document->components->removeSchema($legacy);
            }
            foreach (array_keys($document->components->responses) as $name) {
                if (class_basename($name) === $legacy) {
                    $document->components->removeResponse($name);
                }
            }
        }
    }

    /**
     * @param  array<int, Response|Reference>|null  $responses
     * @param  list<int>  $codes
     */
    private function removeResponses(?array &$responses, array $codes): void
    {
        if ($responses === null) {
            return;
        }

        $responses = array_values(array_filter($responses, function (Response|Reference $response) use ($codes): bool {
            $code = $response instanceof Response ? $response->code : $response->resolve()->code;

            return ! in_array((int) $code, $codes, true);
        }));
    }
}
