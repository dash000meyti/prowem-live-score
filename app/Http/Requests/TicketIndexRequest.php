<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\PaginatesRequests;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class TicketIndexRequest extends FormRequest
{
    use PaginatesRequests;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['page' => ['sometimes', 'integer', 'min:1'], 'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'], 'status' => ['sometimes', Rule::in(['open', 'in_progress', 'waiting', 'resolved', 'reopened'])], 'priority' => ['sometimes', Rule::in(['p1', 'p2', 'p3', 'p4'])], 'assignee_id' => ['sometimes', 'integer'], 'sort' => ['sometimes', Rule::in(['created_at', 'priority', 'sla_due_at', 'status'])], 'direction' => ['sometimes', Rule::in(['asc', 'desc'])]];
    }
}
