<?php

namespace App\Http\Requests;

use App\Enums\UserRole;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreTicketMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['body' => ['required', 'string', 'max:10000'], 'visibility' => [$this->user()?->role === UserRole::Organizer ? 'prohibited' : 'sometimes', Rule::in(['customer', 'internal'])], 'idempotency_key' => ['nullable', 'string', 'max:100']];
    }
}
