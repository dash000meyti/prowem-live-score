<?php

namespace App\Http\Requests;

use App\Enums\ReadinessStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateReadinessRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return ['status' => ['required', Rule::enum(ReadinessStatus::class)], 'message' => ['nullable', 'string', 'max:1000'], 'reason' => ['required', 'string', 'min:5', 'max:1000']];
    }
}
