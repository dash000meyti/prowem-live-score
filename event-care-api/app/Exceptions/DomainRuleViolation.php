<?php

namespace App\Exceptions;

use RuntimeException;

class DomainRuleViolation extends RuntimeException
{
    public function __construct(public readonly string $errorCode, string $message, public readonly int $httpStatus = 409, public readonly mixed $details = null)
    {
        parent::__construct($message);
    }
}
