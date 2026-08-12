<?php

namespace App\OpenApi;

use Dedoc\Scramble\Support\Generator\Types\ObjectType;

class FreeFormObjectType extends ObjectType
{
    public function toArray(): array
    {
        return [...parent::toArray(), 'additionalProperties' => true];
    }
}
