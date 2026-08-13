<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\PaginatesRequests;
use Illuminate\Foundation\Http\FormRequest;

class ActivityIndexRequest extends FormRequest
{
    use PaginatesRequests;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['page' => ['sometimes', 'integer', 'min:1'], 'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'], 'type' => ['sometimes', 'string', 'max:100'], 'actor_id' => ['sometimes', 'integer'], 'from' => ['sometimes', 'date'], 'to' => ['sometimes', 'date', 'after_or_equal:from']];
    }
}
