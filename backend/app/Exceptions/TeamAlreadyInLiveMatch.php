<?php

namespace App\Exceptions;

use DomainException;

class TeamAlreadyInLiveMatch extends DomainException
{
    public const string CODE = 'TEAM_ALREADY_IN_LIVE_MATCH';

    public function __construct(
        public readonly int $conflictingGameId
    ) {
        parent::__construct(
            'One of the teams is already playing another live match.'
        );
    }
}
