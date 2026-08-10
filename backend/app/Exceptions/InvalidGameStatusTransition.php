<?php

namespace App\Exceptions;

use DomainException;

class InvalidGameStatusTransition extends DomainException
{
    public const string CODE = 'INVALID_MATCH_STATUS_TRANSITION';
}
