<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\PaginatesRequests;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class IncidentIndexRequest extends FormRequest
{
    use PaginatesRequests;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['page' => ['sometimes', 'integer', 'min:1'], 'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'], 'status' => ['sometimes', Rule::in(['open', 'acknowledged', 'in_progress', 'resolved'])], 'type' => ['sometimes', Rule::in(['operational', 'technical'])], 'category' => ['sometimes', 'string', 'max:50'], 'severity' => ['sometimes', Rule::in(['low', 'medium', 'high', 'critical'])], 'from' => ['sometimes', 'date'], 'to' => ['sometimes', 'date', 'after_or_equal:from'], 'sort' => ['sometimes', Rule::in(['started_at', 'severity', 'status'])], 'direction' => ['sometimes', Rule::in(['asc', 'desc'])]];
    }
}
