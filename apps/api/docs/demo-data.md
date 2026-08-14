# Demo data

Run `docker compose exec app php artisan migrate:fresh --seed --force`. Dates are anchored relative to seed execution so live/upcoming screens remain useful; external references and fresh-seed IDs are stable.

## Demo credentials

All passwords are `password`.

- Organizer: `organizer@prowem.test`
- Support: `support@prowem.test`
- Support lead: `lead@prowem.test`
- Admin: `admin@prowem.test`
- Other customer Organizer: `other-organizer@prowem.test`

## Scenario 1 — Vienna Summer Cup

- Reference/ID: `VSC-2026` / `1`; status `live`.
- Use for: primary Home → Team Passport → payment verification → Live → incident/ticket/activity flow.
- 16 teams, 42 fixtures, four fields, eight referees. Salzburg United is blocked by payment and warning on check-in. Match #23/Field 3 has an acknowledged referee incident. Field 2 has an in-progress streaming incident linked to exactly one P1 ticket (`EC-VSC-P1-001`).

## Scenario 2 — Alpine Youth Cup

- Reference/ID: `ALP-2026` / `2`; status `preparing`.
- Use for: blocked Home, needs-attention, dimensions, two Team Passports, disabled Start Event.
- Salzburg United has a blocked Payment check and a Check-in warning. Alpine Juniors B has a blocked Roster check. The Event also includes referee and document warnings plus a critical Field 2 streaming-test failure. Starting returns `EVENT_NOT_READY`.

## Scenario 3 — Munich Ready Cup

- Reference/ID: `MRC-2026` / `3`; status `ready`.
- Use for: 100% ready state and Start Event CTA.
- Eight teams, 16 fixtures, two fields, four referees; all team and event checks are ready.

## Scenario 4 — Salzburg Live Operations Cup

- Reference/ID: `SLOC-2026` / `4`; status `live`.
- Use for: operational control without technical support escalation.
- 20 teams, 52 fixtures, five fields; Live Score/Streaming/Graphics ready. Includes open late-team and venue issues, acknowledged critical referee absence, in-progress 12-minute Match #14 delay, resolved history, 26 operational incidents, zero tickets.

## Scenario 5 — Zurich Tech Critical Cup

- Reference/ID: `ZTC-2026` / `5`; status `live`.
- Use for: technical escalation, SLA states, support queue and conversation.
- Three technical incidents and three linked P1 tickets: approaching streaming (`EC-ZTC-P1-001`), waiting graphics (`EC-ZTC-P1-002`), resolved SLA-met Live Score (`EC-ZTC-P1-003`). The first ticket has 26 messages; Organizer sees 25 because the internal node-restart note is filtered.

## Scenario 6 — PROWEM Spring Cup

- Reference/ID: `SPR-2026` / `6`; status `completed`.
- Use for: post-event report.
- 16 teams, 42 matches, one cancellation, non-zero delays, 94% historical kickoff snapshot, four operational/two technical incidents, two resolved P1 tickets and deterministic recommendations.

## Scenario 7 — Graz Cancelled Cup

- Reference/ID: `GCC-2026` / `7`; status `cancelled`.
- Use for: cancelled and empty states.
- Eight teams and 12 cancelled fixtures; no incidents, tickets, or live matches.

## Security account

- `other-organizer@prowem.test` owns `PRIVATE-2026` / fresh-seed Event ID `8`.
- It is absent from the primary Organizer’s event list; primary access to its care routes returns `FORBIDDEN`.

## Pagination datasets

- Vienna: 34 activity records.
- Salzburg Operations: 26 incidents and 50 activities.
- Primary Organizer: exactly 30 notifications with read/unread examples across events.
- Zurich streaming ticket: 26 messages, 25 customer-visible.
