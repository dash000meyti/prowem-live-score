<?php

namespace App\OpenApi;

use Dedoc\Scramble\Extensions\ExceptionToResponseExtension;
use Dedoc\Scramble\Support\Generator\Response;
use Dedoc\Scramble\Support\Generator\Schema;
use Dedoc\Scramble\Support\Generator\Types;
use Dedoc\Scramble\Support\Type\ObjectType;
use Dedoc\Scramble\Support\Type\Type;
use Illuminate\Validation\ValidationException;

class StandardValidationErrorExtension extends ExceptionToResponseExtension
{
    public function shouldHandle(Type $type): bool
    {
        return $type instanceof ObjectType && $type->isInstanceOf(ValidationException::class);
    }

    public function toResponse(Type $type): Response
    {
        $details = (new Types\ObjectType)->additionalProperties((new Types\ArrayType)->setItems(new Types\StringType));
        $error = (new Types\ObjectType)->addProperty('code', (new Types\StringType)->example('VALIDATION_FAILED'))->addProperty('details', $details)->setRequired(['code', 'details']);
        $body = (new Types\ObjectType)->addProperty('success', (new Types\BooleanType)->example(false))->addProperty('message', (new Types\StringType)->example('The given data was invalid.'))->addProperty('error', $error)->setRequired(['success', 'message', 'error']);

        return Response::make(422)->setDescription('Validation failed')->setContent('application/json', Schema::fromType($body));
    }
}
