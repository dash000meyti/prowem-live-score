<?php

namespace App\Services;

use App\Enums\ReadinessStatus;
use App\Enums\ReadinessSubjectType;
use App\Models\Event;
use App\Models\ReadinessCheck;
use Illuminate\Support\Collection;

final class EventReadinessService
{
    public function __construct(private ReadinessCalculator $calculator) {}

    public function summarize(Event $event): array
    {
        $checks = $event->relationLoaded('readinessChecks')
            ? $event->readinessChecks
            : $event->readinessChecks()->get();
        $overall = $this->calculator->calculate($checks);
        $dimensions = $checks->groupBy('dimension')->map(function ($items, $name) {
            $result = $this->calculator->calculate($items);

            return ['key' => $name, 'label' => ucwords(str_replace('_', ' ', $name)), 'status' => $result['status']->value, 'score' => (int) $result['score'], 'ready' => $items->where('status', ReadinessStatus::Ready)->count(), 'total' => $items->count(), 'actions_required' => $items->whereIn('status', [ReadinessStatus::Warning, ReadinessStatus::Blocked])->count()];
        })->values()->all();

        return [...$this->serialize($overall), 'actions_required_count' => $checks->whereIn('status', [ReadinessStatus::Warning, ReadinessStatus::Blocked])->count(), 'dimensions' => $dimensions, 'checks_count' => $checks->count()];
    }

    /** @return array{event_id:int,status:string,score:int,critical_blockers_count:int,actions_required_count:int} */
    public function summaryPayload(Event $event): array
    {
        $summary = $this->summarize($event);

        return ['event_id' => (int) $event->id, 'status' => $summary['status'], 'score' => $summary['score'], 'critical_blockers_count' => $summary['critical_blockers_count'], 'actions_required_count' => $summary['actions_required_count']];
    }

    public function teams(Event $event): Collection
    {
        return $event->teams()->orderBy('name')->get()->map(function ($team) use ($event) {
            $team->checks = ReadinessCheck::query()->where('event_id', $event->id)->where('subject_type', ReadinessSubjectType::Team->value)->where('subject_id', $team->id)->orderBy('check_type')->get();
            $fixture = $event->fixtures()->with('venue')->where(fn ($q) => $q->where('home_team_id', $team->id)->orWhere('away_team_id', $team->id))->orderBy('kickoff_at')->first();
            $team->first_match = $fixture ? ['id' => $fixture->id, 'kickoff_at' => $fixture->kickoff_at->toISOString(), 'field' => $fixture->venue?->name] : null;

            return $team;
        });
    }

    private function serialize(array $result): array
    {
        return ['status' => $result['status']->value, 'score' => $result['score'], 'critical_blockers_count' => $result['critical_blockers_count']];
    }
}
