# Event Care mobile API contract

Base URL: `/api/v1`. Send `Authorization: Bearer <token>`. Successes use `{success,message,data}`; paginated lists also use `meta.pagination` and `links`. Errors use `{success:false,message,error:{code,details}}`.

## Demo scenarios

Use stable references `VSC-2026`, `ALP-2026`, `MRC-2026`, `SLOC-2026`, `ZTC-2026`, `SPR-2026`, and `GCC-2026` for live, blocked, ready, operational, technical, completed, and cancelled screens respectively. Full seeded expectations are in `docs/demo-data.md`.

## Authentication

- `POST /auth/login` — request: `email`, `password`, optional `device_name`; returns token and user. Errors: `INVALID_CREDENTIALS`, `VALIDATION_FAILED`, `RATE_LIMITED`.
- `GET /me` — returns user role and customer. `POST /auth/logout` revokes the active token.

## My Events

- `GET /events/summary` returns counts for all, needs-attention, and every lifecycle status independently of pagination.
- `GET /events` also accepts `search` and `needs_attention=1`; attention is calculated by the API from readiness checks and open incidents/tickets.
- `GET /events/{event}/support-home` returns the active P1 ticket, other open requests, resolved requests, and API-calculated SLA state/remaining time for the Support dashboard.
- `GET /events` — `status`, `from`, `to`, `sort=starts_at|created_at`, `direction`, `page`, `per_page`.
- Returns typed cards: event, nullable venue, counts, readiness summary, open incidents/tickets. Organizer results are customer-scoped.

## Event Home

- `GET /events/{event}/care` — bounded event, readiness summary/dimensions, needs attention, critical incidents, tickets, next matches, recent activity.
- Actions: navigate to readiness, incident, ticket, or live control. Errors: `FORBIDDEN`, `RESOURCE_NOT_FOUND`.
- Realtime: `event.status.changed`, `event.readiness.changed`, `team.readiness.changed`, `incident.*`, `ticket.*`, `activity.created`.

## Readiness

- `GET /events/{event}/readiness` — status, score, critical blocker count, action count, typed dimensions.
- Status is derived from checks; a critical blocked check blocks the event independently of score.

## Readiness Dimension

- `GET /events/{event}/readiness/{dimension}`.
- Dimension: `teams|players|fixtures|referees|venues|staff|live_score|streaming|graphics`.
- Returns dimension summary and actionable items with label, status, message, subject, action, and flexible metadata. Error: `INVALID_READINESS_DIMENSION`.

## Team Passport

- `GET /events/{event}/teams/readiness` — filters `status`, `search`, `page`, `per_page`.
- `GET /events/{event}/teams/{team}/readiness` — team/manager/first match, score, blockers and available actions.

## Team Actions

- `POST /events/{event}/teams/{team}/actions/{operation}`.
- Operation: `verify_payment|check_in|approve_roster|confirm_eligibility|approve_documents`.
- Persists an idempotent operation fact, projects the related readiness check, recalculates team/event summaries, audits, and broadcasts. Error: `INVALID_TEAM_OPERATION`.
- Generic `PATCH /readiness-checks/{id}` is support/admin override only and requires `reason`; Organizer receives `FORBIDDEN`.

## Live Control

- `GET /events/{event}/live` — typed event progress, live/next/delayed matches, operational incidents, system readiness.
- `PATCH /events/{event}/status` — controlled lifecycle. Going live with critical blockers returns `409 EVENT_NOT_READY` with blocker details.

## Incident

- `GET|POST /events/{event}/incidents`; `GET|PATCH /incidents/{incident}`.
- Organizer manages owned operational incidents and can report technical incidents; only support roles update technical incidents.
- Realtime: `incident.created`, `incident.updated`, `incident.resolved`.

## Support

- `GET|POST /events/{event}/tickets` — request fields: `category`, `requested_urgency`, `subject`, `description`; optional service/fixture/venue/idempotency key.
- Priority and SLA are server-calculated. A live technical incident auto-creates one P1 ticket.

## Ticket Detail

- `GET /tickets/{ticket}` — reference, event/incident, service, priority, status, assignee, timestamps, SLA state and resolution.
- `PATCH /tickets/{ticket}` is support administration only; Organizer cannot assign, reprioritize, resolve internally, or write internal notes.
- Realtime: `ticket.created`, `ticket.updated`, `ticket.resolved`.

## Ticket Conversation

- `GET /tickets/{ticket}/messages?page=&per_page=` — chronological, paginated customer-visible conversation.
- `POST /tickets/{ticket}/messages` — Organizer sends `body` and optional `idempotency_key`; `visibility` is prohibited. Support may send `customer|internal`.
- Internal messages are query-filtered for Organizer. Realtime customer messages: `ticket.message.created`.

## Notifications

- `GET /notifications?page=&per_page=`; `PATCH /notifications/{id}/read`; `POST /notifications/read-all`.
- Notifications are user-scoped. Realtime channel: `private-App.Models.User.{userId}`.

## Activity

- `GET /events/{event}/activity` — paginated; filters: activity type, actor, date range. `context` is a nullable JSON object.

## Post-Event Report

- `GET /events/{event}/care-report` — pre-kickoff readiness snapshot, incident/support metrics, blockers and deterministic recommendations.
- SLA compliance and average resolution are `null` when no measurable ticket exists.

## Realtime

- Event channel: `private-events.{eventId}`, authorized by role/customer ownership.
- Immediate events: `event.status.changed`, `event.readiness.changed`, `team.readiness.changed`, `incident.created`, `incident.updated`, `incident.resolved`, `ticket.created`, `ticket.updated`, `ticket.resolved`, `ticket.message.created`, `activity.created`.
- Database/broadcast notifications use the authenticated user's private notification channel.
