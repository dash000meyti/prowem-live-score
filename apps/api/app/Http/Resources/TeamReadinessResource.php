<?php

namespace App\Http\Resources;

use App\Enums\ReadinessStatus;
use App\Models\ReadinessCheck;
use App\Models\Team;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Collection;

/**
 * @mixin Team
 *
 * @property-read array{id: int, kickoff_at: string, field: string|null}|null $first_match
 * @property-read Collection<int, ReadinessCheck> $checks
 */
class TeamReadinessResource extends JsonResource
{
    /**
     * @return array{team: array{id: int, name: string}, manager: array{name: string|null, phone: string|null}, first_match: array{id: int, kickoff_at: string, field: string|null}|null, status: string, score: int, blockers_count: int, actions_required_count: int, checks: list<array{id: int, key: string, label: string, status: string, message: string|null, action: string|null}>}
     */
    public function toArray(Request $request): array
    {
        $checks = collect($this->checks ?? []);

        return ['team' => ['id' => (int) $this->id, 'name' => $this->name], 'manager' => ['name' => $this->manager_name, 'phone' => $this->manager_phone], 'first_match' => $this->first_match ?? null, 'status' => $this->readiness_status->value, 'score' => (int) $this->readiness_score, 'blockers_count' => $checks->where('status', ReadinessStatus::Blocked)->count(), 'actions_required_count' => $checks->whereIn('status', [ReadinessStatus::Blocked, ReadinessStatus::Warning])->count(), 'checks' => $checks->map(fn ($check) => ['id' => (int) $check->id, 'key' => $check->check_type, 'label' => ucwords(str_replace('_', ' ', $check->check_type)), 'status' => $check->status->value, 'message' => $check->message, 'action' => match ($check->check_type) {
            'payment' => 'verify_payment','check_in' => 'check_in','roster' => 'approve_roster','eligibility' => 'confirm_eligibility','documents' => 'approve_documents',default => null
        }])->values()->all()];
    }
}
