<?php

namespace App\Actions;

use App\Enums\IncidentStatus;
use App\Events\EventCareChanged;
use App\Exceptions\DomainRuleViolation;
use App\Models\Incident;
use App\Models\User;
use App\Services\ActivityLogger;
use Illuminate\Support\Facades\DB;

final class UpdateIncident
{
    public function __construct(private ActivityLogger $activity) {}

    public function execute(Incident $incident, array $data, User $actor): Incident
    {
        return DB::transaction(function () use ($incident, $data, $actor) {
            $incident = Incident::query()->lockForUpdate()->findOrFail($incident->id);
            $next = IncidentStatus::from($data['status']);
            $allowed = match ($incident->status) {
                IncidentStatus::Open => [IncidentStatus::Acknowledged, IncidentStatus::InProgress, IncidentStatus::Resolved],IncidentStatus::Acknowledged => [IncidentStatus::InProgress, IncidentStatus::Resolved],IncidentStatus::InProgress => [IncidentStatus::Resolved],IncidentStatus::Resolved => []
            };
            if (! in_array($next, $allowed, true)) {
                throw new DomainRuleViolation('INVALID_INCIDENT_TRANSITION', 'The requested incident transition is invalid.');
            }if ($next === IncidentStatus::Resolved && blank($data['resolution'] ?? null)) {
                throw new DomainRuleViolation('RESOLUTION_REQUIRED', 'A resolution is required to resolve an incident.', 422);
            }$updates = ['status' => $next, 'resolution' => $data['resolution'] ?? $incident->resolution];
            if ($next === IncidentStatus::Acknowledged) {
                $updates['acknowledged_at'] = now();
            }if ($next === IncidentStatus::Resolved) {
                $updates['resolved_at'] = now();
            }$incident->update($updates);
            $this->activity->log($incident->event, 'incident_'.$next->value, "Incident {$next->value}: {$incident->title}", $actor, 'incident', $incident->id);
            EventCareChanged::dispatch($incident->event_id, $next === IncidentStatus::Resolved ? 'incident.resolved' : 'incident.updated', ['id' => $incident->id, 'status' => $next->value]);

            return $incident->load('ticket');
        });
    }
}
