<?php

namespace App\Http\Requests;

use App\Enums\EventStatus;
use App\Http\Requests\Concerns\PaginatesRequests;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class EventIndexRequest extends FormRequest
{
    use PaginatesRequests;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['page' => ['sometimes', 'integer', 'min:1'], 'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'], 'status' => ['sometimes', Rule::enum(EventStatus::class)], 'needs_attention' => ['sometimes', 'boolean'], 'search' => ['sometimes', 'string', 'max:100'], 'from' => ['sometimes', 'date'], 'to' => ['sometimes', 'date', 'after_or_equal:from'], 'sort' => ['sometimes', Rule::in(['starts_at', 'created_at'])], 'direction' => ['sometimes', Rule::in(['asc', 'desc'])]];
    }
}
