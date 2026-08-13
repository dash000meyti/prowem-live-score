<?php

namespace App\Http\Requests;

use App\Enums\TicketPriority;
use App\Enums\TicketStatus;
use App\Enums\UserRole;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateTicketRequest extends FormRequest
{
    public function authorize(): bool
    {
        $ticket = $this->route('ticket');

        return $ticket !== null
            && in_array($this->user()?->role, [UserRole::SupportAgent, UserRole::SupportLead, UserRole::Admin], true)
            && $this->user()->can('view', $ticket->event);
    }

    public function rules(): array
    {
        return ['status' => ['sometimes', Rule::enum(TicketStatus::class)], 'priority' => ['sometimes', Rule::enum(TicketPriority::class)], 'assignee_id' => ['sometimes', 'nullable', 'integer', 'exists:users,id'], 'resolution' => ['nullable', 'string', 'max:5000'], 'resolution_code' => ['nullable', 'string', 'max:100'], 'customer_note' => ['nullable', 'string', 'max:5000'], 'internal_note' => ['nullable', 'string', 'max:5000']];
    }
}
