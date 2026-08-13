<?php

namespace App\Http\Requests\Concerns;

trait PaginatesRequests
{
    public function perPage(): int
    {
        return min(max((int) $this->input('per_page', 20), 1), 100);
    }
}
