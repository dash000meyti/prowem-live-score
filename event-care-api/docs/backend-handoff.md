# PROWEM Event Care backend handoff

## A. Stack

- PHP 8.3.32; Laravel 13.24.0; PostgreSQL 17.10; Redis 7.4.10.
- Laravel Sanctum bearer-token authentication; Laravel Reverb WebSockets.
- Redis queue worker; business mutations remain synchronous/transactional.
- Dedoc Scramble 0.13.40/OpenAPI 3.1; Reverb 1.11.0; Sanctum 4.3.3; PHPUnit 12.5.33; Pint; Larastan 3.10/PHPStan level 8 with baseline.
- Compose: `app`, `nginx`, `postgres`, `redis`, `queue`, `reverb`.

## B. Domain Models

| Model | Table | Purpose / important fields | Relationships / casts |
|---|---|---|---|
| Account | accounts | Customer, plan | events |
| User | users | Identity, account, role | account; role enum; Sanctum, notifications |
| Event | events | Care lifecycle, dates, external reference | account, users, teams, fixtures, venues, checks, incidents, tickets, activities; status enum/dates |
| Team | teams | Tournament projection, manager, readiness projection | event; readiness status enum |
| Fixture | fixtures | Match projection, teams/venue/referee, kickoff/status/delay | venue; kickoff datetime |
| Venue | venues | Field/venue projection | event_id |
| Referee | referees | Referee projection | event_id |
| ReadinessCheck | readiness_checks | Readiness fact/projection per subject/check | event; status/subject enums, JSONB metadata, timestamps |
| TeamOperationState | team_operation_states | Idempotent underlying team-operation fact | event/team/operation/completer/timestamp |
| ReadinessSnapshot | readiness_snapshots | Historical before-kickoff readiness | status enum, score/blocker count/captured timestamp |
| Incident | incidents | Operational/technical issue and correlation | event, ticket; type/severity/status enums, JSONB metadata/timestamps |
| SupportTicket | support_tickets | Escalation/customer support, priority/SLA/resolution | event, incident, assignee, messages; priority/status enums/timestamps |
| TicketMessage | ticket_messages | Customer/internal ticket conversation | ticket, author; visibility/idempotency |
| Activity | activities | Immutable event timeline | actor; JSONB context/occurred timestamp |
| DatabaseNotification | notifications | Laravel persistent user inbox | morph notifiable; JSON payload/read timestamp |

## C. Enums

- `EventStatus`: preparing, ready, live, completed, cancelled.
- `ReadinessStatus`: ready, warning, blocked.
- `ReadinessSubjectType`: event, team, venue, referee, service.
- `ReadinessDimension`: teams, players, fixtures, referees, venues, staff, live_score, streaming, graphics.
- `TeamOperation`: verify_payment, check_in, approve_roster, confirm_eligibility, approve_documents.
- `IncidentType`: operational, technical. `IncidentSeverity`: low, medium, high, critical. `IncidentStatus`: open, acknowledged, in_progress, resolved.
- `TicketPriority`: p1, p2, p3, p4. `TicketStatus`: open, in_progress, waiting, resolved, reopened.
- `UserRole`: organizer, support_agent, support_lead, admin.

## D. Application Services / Actions

| Class | Purpose / input | Side effects / transaction |
|---|---|---|
| ReadinessCalculator | Aggregate checks | Critical/block propagation and 100/50/0 score; pure |
| EventReadinessService | Event summaries/team projections | Read-only aggregation |
| TeamReadinessProjector | Operation fact → check/team projection | Updates check and team inside caller transaction |
| CompleteTeamOperation | Event, team, TeamOperation, actor | Transaction + row lock; operation fact, projection, activity, notification, two broadcasts |
| TransitionEvent | Event, next status, actor | Transaction + lock; validates state/blockers, captures kickoff snapshot, activity/broadcast |
| UpdateReadinessCheck | Privileged override | Transaction + lock; check/team projection, reasoned audit, broadcasts |
| CreateIncident | Event, validated incident, actor | Transaction; duplicate detection, incident/activity, live technical P1 ticket/SLA/notification/broadcast |
| UpdateIncident | Incident transition | Transaction + lock; timestamps, resolution, activity/broadcast |
| CreateSupportTicket | Organizer request | Transaction; idempotency, server priority/SLA, activity, notification/broadcast |
| UpdateTicket | Support administration | Transaction + lock; lifecycle, response/resolution times, activity/broadcast |
| SlaCalculator | Priority, plan, live flag | Response deadline and on_track/approaching/breached/met state |
| ActivityLogger | Event timeline write | Persists activity and immediately broadcasts `activity.created` |
| EventReportService | Completed-event metrics | Reads snapshot/incidents/tickets/fixtures; deterministic recommendations |
| EventCareNotification | Persistent/realtime notification | Laravel database + immediate broadcast channels |

## E. API

- Auth: `POST /auth/login`, `POST /auth/logout`, `GET /me`.
- Events/Home: `GET /events`, `GET /events/{event}/care`, `PATCH /events/{event}/status`.
- Readiness: event, dimension, team list/detail, team operation, privileged check override.
- Live: `GET /events/{event}/live`.
- Incidents: event list/create and incident show/update.
- Support: event ticket list/create, ticket show/support update, message list/create.
- Inbox/Timeline/Report: notifications read APIs, event activity, care report.
- Health/docs: `GET /health`, `/docs/api`, `/docs/api.json`.

## F. Authorization

- `EventPolicy::view`: support roles see all; Organizer only matching `account_id`.
- `manage`: owned Organizer or support lead/admin. `support`: support agent/lead/admin only.
- Organizer can manage owned operations, report technical problems, request support and send customer messages.
- Organizer cannot generic-override readiness, update technical incidents, administer tickets, send/read internal messages, access another customer, or authorize another event channel.
- Ticket/internal message query filters and Resources provide server-side data separation.

## G. Realtime

All `EventCareChanged` broadcasts are immediate on `private-events.{eventId}` with small payloads. Names/triggers: `event.status.changed` (transition), `event.readiness.changed` and `team.readiness.changed` (readiness mutation), `incident.created|updated|resolved`, `ticket.created|updated|resolved`, `ticket.message.created` (customer-visible message), `activity.created`. Laravel notification broadcasts are immediate on `private-App.Models.User.{id}`. Channel middleware plus `routes/channels.php` enforce ownership/support access.

## H. Business Rules

- Check status aggregates blocked > warning > ready; score is average of ready=100, warning=50, blocked=0. Critical blockers independently prevent go-live.
- Team operations first persist unique `TeamOperationState`; `TeamReadinessProjector` derives the readiness check/team projection. Generic check mutation is support/admin only and requires an audit reason.
- Event transitions are explicit; ready→live captures a historical snapshot and fails `409 EVENT_NOT_READY` for critical blockers.
- Any technical incident during a live event auto-creates P1; premium/live SLA modifiers apply. Organizer urgency is advisory for manual tickets.
- Active incident duplication uses correlation lookup plus PostgreSQL partial unique index. Manual tickets/messages/team operations use scoped unique idempotency constraints.
- Report SLA/resolution metrics are null when no measurable data exists.

## I. Database Constraints / Important Indexes

- PostgreSQL check constraints for event/readiness/incident/ticket states.
- Partial unique `(event_id, correlation_key)` for non-resolved incidents.
- Unique event/team/check identity; unique event/team/operation; unique event/ticket idempotency key; unique ticket/message idempotency key.
- Event/status, readiness dimension/status, incident status/type/category/date, ticket status/priority, activity timeline/type indexes.
- JSONB only for readiness/incident metadata and activity context; timestamp columns use timezone-aware types.

## J. Seeded Demo

- Password for all demo users: `password`; Organizer `organizer@prowem.test`, support `support@prowem.test`, lead/admin equivalents in README.
- Scenario seeders are split by event and use `Support\DemoEventBuilder`; important state is derived through `ReadinessCalculator`, `CreateIncident`, `UpdateIncident`, `UpdateTicket`, and `TransitionEvent` rather than HTTP calls.
- Primary references: `VSC-2026` live main flow; `ALP-2026` blocked; `MRC-2026` ready; `SLOC-2026` operational-only; `ZTC-2026` technical/P1/SLA/conversation; `SPR-2026` completed report; `GCC-2026` cancelled.
- Secondary account: `other-organizer@prowem.test`, Event `PRIVATE-2026`. Full state/count reference: `docs/demo-data.md`.

## K. Tests

- `ReadinessCalculatorTest`: blocker/warning propagation, score, critical override.
- `SlaCalculatorTest`: premium live P1 deadline and breached state.
- `EventCareApiTest`: auth/envelopes, dashboard/pagination, readiness override denial, lifecycle conflict, duplicate incident, incident/report, errors.
- `MobileWorkflowsTest`: `/me`, scoped events, team-action idempotency, manual priority/idempotency, internal filtering, notification isolation/read, historical report.
- `SecurityAndBehaviorTest`: operation source fact/projection/broadcast, stable enums/errors, support boundaries, internal leakage, full technical escalation/duplicates, cross-customer IDOR, broadcast authorization.
- `OpenApiTest`: UI/spec rendering, public endpoint security/error noise, nested date-times, domain enums, incident metadata, team-readiness filters, role-sensitive ticket messaging/administration, and primary response typing.

OpenAPI export currently reports seven JR001 diagnostics for intentionally array-backed aggregate resources (`EventListResource`, `EventCareOverviewResource`, `EventReadinessResource`, `EventCareReportResource`, `ReadinessDimensionDetailResource`, `LiveControlResource`, and `NotificationResource`). Their public schemas are explicitly finalized by the document transformers and regression-tested; no generated primary collection contains empty `items`, and no structured primary response is documented as a string.
- `DemoSeedDataTest`: seven scenario contracts, derived readiness/start rules, escalation/conversation visibility, report, cancelled state, pagination and account isolation.

## L. Known Limitations

- Fixture/team/venue/referee data are local projections; no production core-PROWEM synchronization adapter exists.
- Attachments are not implemented.
- Generic Event Care broadcasts use one event class with semantic `broadcastAs` names rather than one PHP class per domain event.
- Static analysis has an existing generated baseline; new analysis passes against it.
