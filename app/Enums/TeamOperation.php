<?php

namespace App\Enums;

enum TeamOperation: string
{
    case VerifyPayment = 'verify_payment';
    case CheckIn = 'check_in';
    case ApproveRoster = 'approve_roster';
    case ConfirmEligibility = 'confirm_eligibility';
    case ApproveDocuments = 'approve_documents';

    public function checkType(): string
    {
        return match ($this) {
            self::VerifyPayment => 'payment',
            self::CheckIn => 'check_in',
            self::ApproveRoster => 'roster',
            self::ConfirmEligibility => 'eligibility',
            self::ApproveDocuments => 'documents',
        };
    }

    public function label(): string
    {
        return ucwords(str_replace('_', ' ', $this->value));
    }
}
