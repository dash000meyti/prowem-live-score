<?php

namespace App\OpenApi;

use Dedoc\Scramble\Contracts\DocumentTransformer;
use Dedoc\Scramble\OpenApiContext;
use Dedoc\Scramble\Support\Generator\OpenApi;
use Dedoc\Scramble\Support\Generator\Operation;
use Dedoc\Scramble\Support\Generator\Parameter;
use Dedoc\Scramble\Support\Generator\Response;
use Dedoc\Scramble\Support\Generator\Schema;
use Dedoc\Scramble\Support\Generator\Types;

class OperationDocumentationTransformer implements DocumentTransformer
{
    /** @var array<string, array{0:string,1:string}> */
    private const OPERATIONS = [
        'POST /auth/login' => ['Authenticate', 'Exchange valid demo or customer credentials for a Sanctum bearer token.'],
        'POST /auth/logout' => ['Log out', 'Revoke the current Sanctum access token.'],
        'GET /me' => ['Get current user', 'Return the authenticated user and customer context.'],
        'GET /events' => ['List organizer events', 'Return the events visible to the authenticated user as paginated mobile cards.'],
        'GET /events/{event}/care' => ['Get Event Care overview', 'Return the bounded aggregate used by the Event Care mobile home.'],
        'GET /events/{event}/lookups' => ['Get event form lookups', 'Return venues, fixtures, and support staff used by incident and ticket forms. Staff is included only for support roles.'],
        'GET /events/{event}/readiness' => ['Get event readiness', 'Return derived readiness status, score, blockers, and dimensions.'],
        'GET /events/{event}/readiness/{dimension}' => ['Get readiness dimension detail', 'Explain the checks and actions behind one supported readiness dimension.'],
        'GET /events/{event}/teams/readiness' => ['List team readiness', 'Filter and paginate derived team readiness cards.'],
        'GET /events/{event}/teams/{team}/readiness' => ['Get team readiness', 'Return the Team Passport readiness checks and available actions.'],
        'POST /events/{event}/teams/{team}/actions/{operation}' => ['Complete team readiness operation', 'Perform an organizer business action and return recalculated team readiness.'],
        'PATCH /events/{event}/status' => ['Transition event status', 'Apply a controlled event lifecycle transition. Going live is rejected while critical blockers exist.'],
        'GET /events/{event}/live' => ['Get live event control', 'Return bounded fixture, incident, progress, and service-health data for match day.'],
        'GET /events/{event}/incidents' => ['List event incidents', 'Filter, sort, and paginate operational and technical incidents.'],
        'POST /events/{event}/incidents' => ['Report incident', 'Create an incident; qualifying live technical incidents are escalated automatically.'],
        'GET /incidents/{incident}' => ['Get incident', 'Return an incident and its linked support ticket when present.'],
        'PATCH /incidents/{incident}' => ['Update incident', 'Apply a valid incident lifecycle change. Technical incident administration requires support access.'],
        'GET /events/{event}/tickets' => ['List support tickets', 'Filter, sort, and paginate support tickets for an event.'],
        'POST /events/{event}/tickets' => ['Create support request', 'Create an organizer support request with server-calculated priority and SLA.'],
        'GET /tickets/{ticket}' => ['Get support ticket', 'Return customer-safe ticket details including derived SLA state.'],
        'PATCH /tickets/{ticket}' => ['Administer support ticket', 'Support agent, support lead, or administrator only. Assign, prioritize, and transition a ticket.'],
        'GET /tickets/{ticket}/messages' => ['List ticket messages', 'Return messages oldest first; organizers receive customer-visible messages only.'],
        'POST /tickets/{ticket}/messages' => ['Send support message', 'Organizer messages are always customer-visible. Only support roles may set visibility to internal.'],
        'GET /notifications' => ['List notifications', 'Return the authenticated user’s persistent notification inbox.'],
        'PATCH /notifications/{notification}/read' => ['Mark notification read', 'Mark one notification owned by the authenticated user as read.'],
        'POST /notifications/read-all' => ['Mark all notifications read', 'Mark all notifications owned by the authenticated user as read.'],
        'GET /events/{event}/activity' => ['Get event activity', 'Filter and paginate the Event Care audit timeline.'],
        'GET /events/{event}/care-report' => ['Get completed Event Care report', 'Return derived readiness history, incident, support, and recommendation metrics.'],
        'PATCH /readiness-checks/{readinessCheck}' => ['Override readiness check', 'Support agent, support lead, or administrator only. An audit reason is required.'],
        'GET /health' => ['Check service health', 'Public dependency health check for the application, PostgreSQL, and Redis.'],
        'GET /broadcasting/auth' => ['Authorize broadcast channel', 'Authorize the authenticated user for a private Event Care channel.'],
    ];

    public function handle(OpenApi $document, OpenApiContext $context): void
    {
        foreach ($document->paths as $path) {
            foreach ($path->operations as $operation) {
                $publicPath = '/'.ltrim((string) preg_replace('#^/?api/v1#', '', $path->path), '/');
                $key = strtoupper($operation->method).' '.$publicPath;
                $successDescription = 'Request completed successfully';
                if (isset(self::OPERATIONS[$key])) {
                    [$summary, $description] = self::OPERATIONS[$key];
                    $operation->summary($summary)->description($description);
                    $successDescription = $summary;
                }

                foreach ($operation->responses ?? [] as $response) {
                    if ($response instanceof Response && is_numeric($response->code) && (int) $response->code >= 200 && (int) $response->code < 300 && $response->description === '') {
                        $response->setDescription($successDescription);
                    }
                }

                if ($key === 'GET /events/{event}/teams/readiness') {
                    $this->addTeamReadinessParameters($operation);
                }
            }
        }

        $this->documentTicketMessageVisibility($document);
    }

    private function addTeamReadinessParameters(Operation $operation): void
    {
        $existing = collect($operation->parameters)->filter(fn ($parameter) => $parameter instanceof Parameter)->map(fn (Parameter $parameter) => $parameter->name)->all();
        $parameters = [
            Parameter::make('status', 'query')->setSchema(Schema::fromType((new Types\StringType)->enum(['ready', 'warning', 'blocked'])))->description('Filter by derived readiness status.'),
            Parameter::make('search', 'query')->setSchema(Schema::fromType(new Types\StringType))->description('Case-insensitive team name search.'),
            Parameter::make('page', 'query')->setSchema(Schema::fromType((new Types\IntegerType)->setMin(1))),
            Parameter::make('per_page', 'query')->setSchema(Schema::fromType((new Types\IntegerType)->setMin(1)->setMax(100))),
        ];

        $operation->addParameters(array_values(array_filter($parameters, fn (Parameter $parameter) => ! in_array($parameter->name, $existing, true))));
    }

    private function documentTicketMessageVisibility(OpenApi $document): void
    {
        $schema = collect($document->components->schemas)->first(fn ($schema, $name) => class_basename($name) === 'StoreTicketMessageRequest');
        if (! $schema?->type instanceof Types\ObjectType) {
            return;
        }

        $schema->type->addProperty(
            'visibility',
            (new Types\StringType)
                ->enum(['customer', 'internal'])
                ->setDescription('Optional for support roles only. Organizers must omit this field; their messages are customer-visible.')
        );
    }
}
