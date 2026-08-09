<?php

namespace App\Http\Requests;

use App\Enums\GameStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateMatchResultRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'home_score' => [
                'required',
                'integer',
                'min:0',
                'max:65535',
            ],

            'away_score' => [
                'required',
                'integer',
                'min:0',
                'max:65535',
            ],

            'status' => [
                'required',
                'string',
                Rule::in([
                    GameStatus::InPlay->value,
                    GameStatus::Finished->value,
                ]),
            ],
        ];
    }
}
