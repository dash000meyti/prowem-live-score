<?php

namespace App\OpenApi;

use Dedoc\Scramble\Contracts\DocumentTransformer;
use Dedoc\Scramble\OpenApiContext;
use Dedoc\Scramble\Support\Generator\OpenApi;
use Dedoc\Scramble\Support\Generator\Reference;
use Dedoc\Scramble\Support\Generator\Schema;
use Dedoc\Scramble\Support\Generator\Types;

class ProductSchemaDocumentTransformer implements DocumentTransformer
{
    public function handle(OpenApi $document, OpenApiContext $context): void
    {
        $this->ensureDomainEnums($document);
        $dimension = (new Types\ObjectType)
            ->addProperty('key', $this->enumRef($document, 'ReadinessDimension'))
            ->addProperty('label', new Types\StringType)
            ->addProperty('status', $this->enumRef($document, 'ReadinessStatus'))
            ->addProperty('score', new Types\IntegerType)
            ->addProperty('ready', new Types\IntegerType)
            ->addProperty('total', new Types\IntegerType)
            ->addProperty('actions_required', new Types\IntegerType)
            ->setRequired(['key', 'label', 'status', 'score', 'ready', 'total', 'actions_required']);
        $dimensionRef = $document->components->addSchema('ReadinessDimensionSummary', Schema::fromType($dimension));
        $summary = (new Types\ObjectType)
            ->addProperty('status', $this->enumRef($document, 'ReadinessStatus'))
            ->addProperty('score', new Types\IntegerType)
            ->addProperty('critical_blockers_count', new Types\IntegerType)
            ->addProperty('actions_required_count', new Types\IntegerType)
            ->addProperty('checks_count', new Types\IntegerType)
            ->addProperty('dimensions', (new Types\ArrayType)->setItems($dimensionRef))
            ->setRequired(['status', 'score', 'critical_blockers_count', 'actions_required_count']);
        $summaryRef = $document->components->addSchema('ReadinessSummary', Schema::fromType($summary));
        $slaStatusRef = $document->components->addSchema('SlaStatus', Schema::fromType(
            (new Types\StringType)->enum(['on_track', 'approaching', 'breached', 'met'])
        ));

        $venue = (new Types\ObjectType)->addProperty('id', new Types\IntegerType)->addProperty('name', new Types\StringType)->setRequired(['id', 'name'])->nullable(true);
        $this->properties($document, 'EventListResource', ['venue' => $venue, 'readiness' => $summaryRef, 'status' => $this->enumRef($document, 'EventStatus')]);
        $this->properties($document, 'EventCareOverviewResource', ['readiness' => $summaryRef, 'readiness_dimensions' => (new Types\ArrayType)->setItems($dimensionRef)]);
        $this->properties($document, 'EventReadinessResource', ['status' => $this->enumRef($document, 'ReadinessStatus'), 'dimensions' => (new Types\ArrayType)->setItems($dimensionRef)]);
        $this->properties($document, 'LiveControlResource', ['system_status' => $summaryRef]);
        $this->properties($document, 'NotificationResource', ['event_id' => (new Types\IntegerType)->nullable(true)]);
        $this->properties($document, 'ActivityResource', ['context' => (new FreeFormObjectType)->nullable(true)]);
        $this->properties($document, 'IncidentResource', ['metadata' => (new FreeFormObjectType)->nullable(true), 'type' => $this->enumRef($document, 'IncidentType'), 'severity' => $this->enumRef($document, 'IncidentSeverity'), 'status' => $this->enumRef($document, 'IncidentStatus')]);
        $this->properties($document, 'ReadinessCheckResource', ['metadata' => (new FreeFormObjectType)->nullable(true), 'subject_type' => $this->enumRef($document, 'ReadinessSubjectType'), 'dimension' => $this->enumRef($document, 'ReadinessDimension'), 'status' => $this->enumRef($document, 'ReadinessStatus')]);
        $this->properties($document, 'SupportTicketResource', ['priority' => $this->enumRef($document, 'TicketPriority'), 'status' => $this->enumRef($document, 'TicketStatus'), 'sla_status' => $slaStatusRef]);
        $this->properties($document, 'EventResource', ['status' => $this->enumRef($document, 'EventStatus')]);
        $this->fixEventCareEvent($document);
        $this->fixTeamReadiness($document);
        $this->fixLiveEvent($document);
        $this->fixIncidentRequest($document);
        $this->fixDimensionDetail($document);
        $this->fixFixtureDates($document, 'LiveControlResource', ['live_matches', 'next_matches', 'delayed_matches']);
        $this->fixFixtureDates($document, 'EventCareOverviewResource', ['next_matches']);
        $this->fixFixtureDates($document, 'EventCareLookupsResource', ['fixtures']);

        foreach (['EventListResource' => ['starts_at', 'ends_at'], 'EventResource' => ['starts_at', 'ends_at', 'completed_at'], 'IncidentResource' => ['started_at', 'acknowledged_at', 'resolved_at'], 'SupportTicketResource' => ['created_at', 'first_response_at', 'sla_due_at', 'resolved_at'], 'TicketMessageResource' => ['created_at'], 'ActivityResource' => ['occurred_at'], 'NotificationResource' => ['read_at', 'created_at'], 'ReadinessCheckResource' => ['last_checked_at', 'resolved_at']] as $schema => $fields) {
            $this->dateTimes($document, $schema, $fields);
        }
    }

    private function fixEventCareEvent(OpenApi $document): void
    {
        $event = $this->objectProperty($document, 'EventCareOverviewResource', 'event');
        if (! $event) {
            return;
        }

        $event->addProperty('status', $this->enumRef($document, 'EventStatus'));
        foreach (['starts_at', 'ends_at'] as $field) {
            $event->addProperty($field, (new Types\StringType)->format('date-time'));
        }
        $event->addProperty('completed_at', (new Types\StringType)->format('date-time')->nullable(true));
    }

    private function fixTeamReadiness(OpenApi $document): void
    {
        if (! $document->components->hasSchema('TeamReadinessResource') || ! $document->components->schemas['TeamReadinessResource']->type instanceof Types\ObjectType) {
            return;
        }

        $resource = $document->components->schemas['TeamReadinessResource']->type;
        $resource->addProperty('status', $this->enumRef($document, 'ReadinessStatus'));
        $firstMatch = $resource->getProperty('first_match');
        if ($firstMatch instanceof Types\ObjectType) {
            $firstMatch->addProperty('kickoff_at', (new Types\StringType)->format('date-time'));
        }
        $checks = $resource->getProperty('checks');
        if ($checks instanceof Types\ArrayType && $checks->items instanceof Types\ObjectType) {
            $checks->items->addProperty('status', $this->enumRef($document, 'ReadinessStatus'));
        }
    }

    private function fixLiveEvent(OpenApi $document): void
    {
        $event = $this->objectProperty($document, 'LiveControlResource', 'event');
        $event?->addProperty('status', $this->enumRef($document, 'EventStatus'));
    }

    private function fixIncidentRequest(OpenApi $document): void
    {
        $this->properties($document, 'StoreIncidentRequest', ['metadata' => (new FreeFormObjectType)->nullable(true)]);
    }

    private function ensureDomainEnums(OpenApi $document): void
    {
        foreach ([
            'EventStatus' => ['preparing', 'ready', 'live', 'completed', 'cancelled'],
            'ReadinessStatus' => ['ready', 'warning', 'blocked'],
            'ReadinessDimension' => ['teams', 'players', 'fixtures', 'referees', 'venues', 'staff', 'live_score', 'streaming', 'graphics'],
            'ReadinessSubjectType' => ['event', 'team', 'venue', 'referee', 'service'],
            'TeamOperation' => ['verify_payment', 'check_in', 'approve_roster', 'confirm_eligibility', 'approve_documents'],
            'IncidentType' => ['operational', 'technical'],
            'IncidentSeverity' => ['low', 'medium', 'high', 'critical'],
            'IncidentStatus' => ['open', 'acknowledged', 'in_progress', 'resolved'],
            'TicketPriority' => ['p1', 'p2', 'p3', 'p4'],
            'TicketStatus' => ['open', 'in_progress', 'waiting', 'resolved', 'reopened'],
            'UserRole' => ['organizer', 'support_agent', 'support_lead', 'admin'],
        ] as $name => $values) {
            if (! $document->components->hasSchema($name)) {
                $document->components->addSchema($name, Schema::fromType((new Types\StringType)->enum($values)));
            }
        }
    }

    private function objectProperty(OpenApi $document, string $schemaName, string $property): ?Types\ObjectType
    {
        if (! $document->components->hasSchema($schemaName) || ! $document->components->schemas[$schemaName]->type instanceof Types\ObjectType) {
            return null;
        }

        $value = $document->components->schemas[$schemaName]->type->getProperty($property);

        return $value instanceof Types\ObjectType ? $value : null;
    }

    private function enumRef(OpenApi $document, string $name): Reference|Types\StringType
    {
        return $document->components->hasSchema($name) ? new Reference('schemas', $name, $document->components) : new Types\StringType;
    }

    /** @param array<string, Types\Type|Reference> $properties */
    private function properties(OpenApi $document, string $schemaName, array $properties): void
    {
        $schema = $this->schema($document, $schemaName);
        if (! $schema?->type instanceof Types\ObjectType) {
            return;
        }
        foreach ($properties as $name => $type) {
            $schema->type->addProperty($name, $type);
        }
    }

    private function schema(OpenApi $document, string $schemaName): ?Schema
    {
        foreach ($document->components->schemas as $name => $schema) {
            if ($name === $schemaName || class_basename($name) === $schemaName) {
                return $schema;
            }
        }

        return null;
    }

    /** @param list<string> $fields */
    private function dateTimes(OpenApi $document, string $schemaName, array $fields): void
    {
        if (! $document->components->hasSchema($schemaName) || ! $document->components->schemas[$schemaName]->type instanceof Types\ObjectType) {
            return;
        }
        foreach ($fields as $field) {
            $nullable = in_array($field, ['completed_at', 'acknowledged_at', 'resolved_at', 'first_response_at', 'read_at', 'last_checked_at'], true);
            $document->components->schemas[$schemaName]->type->addProperty($field, (new Types\StringType)->format('date-time')->nullable($nullable));
        }
    }

    private function fixDimensionDetail(OpenApi $document): void
    {
        if (! $document->components->hasSchema('ReadinessDimensionDetailResource')) {
            return;
        }
        $resource = $document->components->schemas['ReadinessDimensionDetailResource']->type;
        if (! $resource instanceof Types\ObjectType || ! ($items = $resource->getProperty('items')) instanceof Types\ArrayType || ! $items->items instanceof Types\ObjectType) {
            return;
        }
        $items->items->addProperty('status', $this->enumRef($document, 'ReadinessStatus'));
        $items->items->addProperty('metadata', (new FreeFormObjectType)->nullable(true));
        $summary = $resource->getProperty('summary');
        if ($summary instanceof Types\ObjectType) {
            $summary->addProperty('status', $this->enumRef($document, 'ReadinessStatus'));
        }
    }

    /** @param list<string> $fields */
    private function fixFixtureDates(OpenApi $document, string $schemaName, array $fields): void
    {
        if (! $document->components->hasSchema($schemaName) || ! $document->components->schemas[$schemaName]->type instanceof Types\ObjectType) {
            return;
        }
        foreach ($fields as $field) {
            $items = $document->components->schemas[$schemaName]->type->getProperty($field);
            if ($items instanceof Types\ArrayType && $items->items instanceof Types\ObjectType) {
                $items->items->addProperty('kickoff_at', (new Types\StringType)->format('date-time'));
            }
        }
    }
}
