<?php

namespace App\Http\Requests;

use App\Enums\IncidentSeverity;
use App\Enums\IncidentType;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreIncidentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return ['type' => ['required', Rule::enum(IncidentType::class)], 'category' => ['required', 'string', Rule::in(['team_absent', 'team_late', 'referee_absent', 'match_delay', 'venue_issue', 'player_eligibility', 'staff_issue', 'live_score', 'streaming', 'graphics', 'platform', 'other'])], 'severity' => ['required', Rule::enum(IncidentSeverity::class)], 'title' => ['required', 'string', 'max:200'], 'description' => ['required', 'string', 'max:5000'], 'fixture_id' => ['nullable', 'integer', 'exists:fixtures,id'], 'venue_id' => ['nullable', 'integer', 'exists:venues,id'], 'correlation_key' => ['nullable', 'string', 'max:160'], 'started_at' => ['nullable', 'date'], 'metadata' => ['nullable', 'array']];
    }

    /** @return array<int, callable(Validator): void> */
    public function after(): array
    {
        return [function (Validator $validator): void {
            $technical = ['live_score', 'streaming', 'graphics', 'platform'];
            $type = $this->input('type');
            $category = $this->input('category');

            if ($category !== 'other' && (($type === 'technical') !== in_array($category, $technical, true))) {
                $validator->errors()->add('category', 'The category does not belong to the selected incident type.');
            }
        }];
    }

    protected function prepareForValidation(): void
    {
        $this->merge(['title' => is_string($this->title) ? trim($this->title) : $this->title]);
    }
}
