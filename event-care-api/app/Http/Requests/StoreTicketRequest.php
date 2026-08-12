<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreTicketRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $eventId = $this->route('event')?->getKey();

        return ['category' => ['required', 'string', 'max:60'], 'requested_urgency' => ['required', Rule::in(['critical', 'high', 'normal', 'low'])], 'subject' => ['required', 'string', 'max:200'], 'description' => ['required', 'string', 'max:5000'], 'affected_service' => ['nullable', Rule::in(['live_score', 'streaming', 'graphics', 'platform', 'other'])], 'fixture_id' => ['nullable', 'integer', Rule::exists('fixtures', 'id')->where('event_id', $eventId)], 'venue_id' => ['nullable', 'integer', Rule::exists('venues', 'id')->where('event_id', $eventId)], 'idempotency_key' => ['nullable', 'string', 'max:100']];
    }
}
