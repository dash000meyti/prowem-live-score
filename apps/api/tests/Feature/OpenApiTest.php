<?php

namespace Tests\Feature;

use Tests\TestCase;

class OpenApiTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->app->detectEnvironment(fn () => 'local');
    }

    public function test_openapi_document_and_ui_render(): void
    {
        $this->get('/docs/api.json')->assertOk()->assertJsonPath('openapi', '3.1.0');
        $this->get('/docs/api')->assertOk()->assertSee('PROWEM', false);
        $spec = $this->get('/docs/api.json')->json();
        $this->assertSame('array', $spec['paths']['/events']['get']['responses']['200']['content']['application/json']['schema']['properties']['data']['type']);
        $this->assertSame('integer', $spec['components']['schemas']['EventCareReportResource']['properties']['match_count']['type']);
        $this->assertSame('array', $spec['components']['schemas']['EventCareReportResource']['properties']['recommendations']['type']);
        $this->assertSame('#/components/schemas/ApiError', $spec['paths']['/events']['get']['responses']['401']['content']['application/json']['schema']['$ref']);
        $this->assertSame(['object', 'null'], $spec['components']['schemas']['EventListResource']['properties']['venue']['type']);
        $this->assertSame('#/components/schemas/ReadinessSummary', $spec['components']['schemas']['EventListResource']['properties']['readiness']['$ref']);
        $this->assertSame('#/components/schemas/ReadinessSummary', $spec['components']['schemas']['LiveControlResource']['properties']['system_status']['$ref']);
        $this->assertSame('#/components/schemas/IncidentResource', $spec['components']['schemas']['LiveControlResource']['properties']['operational_incidents']['items']['$ref']);
        $this->assertSame('array', $spec['components']['schemas']['ReadinessDimensionDetailResource']['properties']['items']['type']);
        $this->assertSame(['integer', 'null'], $spec['components']['schemas']['NotificationResource']['properties']['event_id']['type']);
        $this->assertTrue($spec['components']['schemas']['ActivityResource']['properties']['context']['additionalProperties']);
        $this->assertTrue($spec['components']['schemas']['IncidentResource']['properties']['metadata']['additionalProperties']);
        $this->assertSame('date-time', $spec['components']['schemas']['EventListResource']['properties']['starts_at']['format']);
        $this->assertSame(['number', 'null'], $spec['components']['schemas']['EventCareReportResource']['properties']['support']['properties']['sla_compliance_percent']['type']);
        $this->assertArrayNotHasKey('type', $spec['components']['schemas']['ApiError']['properties']['error']['properties']['details']);
        $this->assertArrayNotHasKey('AuthenticationException', $spec['components']['schemas']);
        $this->assertArrayNotHasKey('AuthorizationException', $spec['components']['schemas']);
        $this->assertArrayNotHasKey('ModelNotFoundException', $spec['components']['schemas']);
        $this->assertSame('#/components/schemas/ReadinessDimension', collect($spec['paths']['/events/{event}/readiness/{dimension}']['get']['parameters'])->firstWhere('name', 'dimension')['schema']['$ref']);
        $this->assertSame('#/components/schemas/TeamOperation', collect($spec['paths']['/events/{event}/teams/{team}/actions/{operation}']['post']['parameters'])->firstWhere('name', 'operation')['schema']['$ref']);
        $this->assertStringNotContainsString('"items":{}', json_encode($spec['paths'], JSON_THROW_ON_ERROR));
    }

    public function test_openapi_public_and_role_sensitive_operations_are_accurate(): void
    {
        $spec = $this->get('/docs/api.json')->assertOk()->json();
        $health = $spec['paths']['/health']['get'];
        $login = $spec['paths']['/auth/login']['post'];

        $this->assertSame([], $health['security']);
        $this->assertArrayNotHasKey('401', $health['responses']);
        $this->assertArrayNotHasKey('403', $health['responses']);
        $this->assertArrayNotHasKey('429', $health['responses']);
        $this->assertSame([], $login['security']);
        $this->assertArrayNotHasKey('403', $login['responses']);
        $this->assertSame('Administer support ticket', $spec['paths']['/tickets/{ticket}']['patch']['summary']);
        $this->assertStringContainsString('Support agent', $spec['paths']['/tickets/{ticket}']['patch']['description']);
        $this->assertStringContainsString('audit reason is required', strtolower($spec['paths']['/readiness-checks/{readinessCheck}']['patch']['description']));
        $this->assertStringContainsString('Organizers must omit', $spec['components']['schemas']['StoreTicketMessageRequest']['properties']['visibility']['description']);

        $this->assertArrayNotHasKey('AuthenticationException', $spec['components']['responses'] ?? []);
        $this->assertArrayNotHasKey('AuthorizationException', $spec['components']['responses'] ?? []);
        $this->assertArrayNotHasKey('ModelNotFoundException', $spec['components']['responses'] ?? []);
    }

    public function test_openapi_timestamps_enums_metadata_and_team_filters_are_typed(): void
    {
        $spec = $this->get('/docs/api.json')->assertOk()->json();
        $schemas = $spec['components']['schemas'];

        $this->assertSame('date-time', $schemas['EventCareOverviewResource']['properties']['event']['properties']['starts_at']['format']);
        $this->assertSame('date-time', $schemas['EventCareOverviewResource']['properties']['event']['properties']['completed_at']['format']);
        $this->assertContains('null', $schemas['EventCareOverviewResource']['properties']['event']['properties']['completed_at']['type']);
        $this->assertSame('date-time', $schemas['TeamReadinessResource']['properties']['first_match']['properties']['kickoff_at']['format']);
        $this->assertSame('#/components/schemas/ReadinessStatus', $schemas['TeamReadinessResource']['properties']['status']['$ref']);
        $this->assertSame('#/components/schemas/ReadinessStatus', $schemas['TeamReadinessResource']['properties']['checks']['items']['properties']['status']['$ref']);
        $this->assertSame('#/components/schemas/ReadinessDimension', $schemas['ReadinessCheckResource']['properties']['dimension']['$ref']);
        $this->assertSame('#/components/schemas/ReadinessSubjectType', $schemas['ReadinessCheckResource']['properties']['subject_type']['$ref']);
        $this->assertSame('#/components/schemas/SlaStatus', $schemas['SupportTicketResource']['properties']['sla_status']['$ref']);
        $this->assertSame(['object', 'null'], $schemas['StoreIncidentRequest']['properties']['metadata']['type']);
        $this->assertTrue($schemas['StoreIncidentRequest']['properties']['metadata']['additionalProperties']);

        $parameters = collect($spec['paths']['/events/{event}/teams/readiness']['get']['parameters'])->keyBy('name');
        $this->assertSame(['ready', 'warning', 'blocked'], $parameters['status']['schema']['enum']);
        $this->assertSame('string', $parameters['search']['schema']['type']);
        $this->assertSame(1, $parameters['page']['schema']['minimum']);
        $this->assertSame(100, $parameters['per_page']['schema']['maximum']);
    }

    public function test_openapi_primary_operations_have_summaries_and_typed_collections(): void
    {
        $spec = $this->get('/docs/api.json')->assertOk()->json();
        $primary = ['/events', '/events/{event}/care', '/events/{event}/readiness', '/events/{event}/teams/readiness', '/events/{event}/live', '/events/{event}/incidents', '/events/{event}/tickets', '/tickets/{ticket}/messages', '/notifications', '/events/{event}/activity', '/events/{event}/care-report'];

        foreach ($primary as $path) {
            $operation = $spec['paths'][$path]['get'];
            $this->assertNotEmpty($operation['summary'], $path.' must have a summary.');
            $this->assertNotSame('', $operation['responses']['200']['description']);
        }

        $encodedPaths = json_encode($spec['paths'], JSON_THROW_ON_ERROR);
        $this->assertStringNotContainsString('"items":{}', $encodedPaths);
        foreach ($primary as $path) {
            $data = $spec['paths'][$path]['get']['responses']['200']['content']['application/json']['schema']['properties']['data'];
            $this->assertNotSame('string', $data['type'] ?? null, $path.' data must be structured.');
        }
    }
}
