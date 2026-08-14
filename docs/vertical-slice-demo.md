# Event Care vertical-slice demo

This walkthrough uses the deterministic data created by:

```bash
docker compose exec app php artisan migrate:fresh --seed --force
```

Sign in as `organizer@prowem.test` with password `password`. Use event external references in this document rather than database IDs.

## Demo walkthrough

1. Open **My Events** and point out the lifecycle range: blocked/preparing `ALP-2026`, ready `MRC-2026`, live `VSC-2026`, and completed `SPR-2026`.
2. Open `ALP-2026`. The preparing Home leads with critical blockers and actions rather than analytics. Readiness shows the API-derived dimensions and the backend rejects an attempted start with `EVENT_NOT_READY`.
3. In `ALP-2026`, open the first blocker or Teams → **Salzburg United**. Its Payment check is blocked. Choose **Verify Payment**, review the confirmation, and confirm. The team-operation fact is persisted, team/Event readiness is recalculated, activity is recorded, and readiness events are broadcast. Refreshing or reopening the passport retains the result.
4. Open `MRC-2026`. It is 100% ready with no critical blockers. Choose **Start event**, confirm, and observe the real `ready → live` transition. My Events and Event Home refresh to the Live experience.
5. Open `VSC-2026` for the same-event match-day story. Its Live Home exposes both the Organizer-owned referee incident and the PROWEM-owned streaming incident/support state.
6. Open the **Referee unavailable** operational incident. Acknowledge/start handling if applicable, choose **Resolve issue**, enter `Backup referee confirmed.`, and submit. Reopening the incident shows the persisted resolution and activity history.
7. Open the **Streaming unavailable** technical incident. The Organizer sees PROWEM ownership, the linked P1 ticket, assigned support context and SLA, but no support-admin controls.
8. Open ticket `EC-VSC-P1-001` (or use `ZTC-2026` / `EC-ZTC-P1-001` for the longer seeded conversation). Send a message. Only customer-visible messages appear for the Organizer; the seeded internal Zurich diagnostic note stays hidden.
9. Open completed event `SPR-2026` and choose **View Event Care report**. The report uses its persisted 94% kickoff snapshot, 42 matches, incident/ticket history, SLA measurements and deterministic recommendations.

The walkthrough intentionally uses `MRC-2026` for the destructive Start transition so the rich `VSC-2026` live incident/support state remains repeatable after every fresh seed.

## Capability and API mapping

| Experience | API source / mutation | Refresh behavior |
|---|---|---|
| My Events | `GET /events`, `GET /events/summary` | query refetch |
| Event Home | `GET /events/{event}/care` | web Event channel; mobile 15s fallback + pull-to-refresh |
| Readiness | `GET /events/{event}/readiness`, `GET /readiness/{dimension}` | Event readiness invalidation/refetch |
| Team Passport | `GET /teams/{team}/readiness` | team/Event invalidation or refetch |
| Verify Payment | `POST /teams/{team}/actions/verify_payment` | disabled while saving; persisted response + refetch |
| Start Event | `PATCH /events/{event}/status` | guarded mutation + status broadcast/refetch |
| Live Control | `GET /events/{event}/live` | Event invalidation/refetch |
| Incident Detail | `GET /incidents/{incident}` | Event invalidation/refetch |
| Resolve Incident | `PATCH /incidents/{incident}` | resolution required; disabled while saving |
| Support Home | `GET /events/{event}/support-home` | Event invalidation/refetch |
| Ticket Conversation | `GET/POST /tickets/{ticket}/messages` | web Event channel; mobile 10s fallback + pull-to-refresh |
| Event Care Report | `GET /events/{event}/care-report` | persisted history only |

Web uses the private Reverb Event channel and invalidates React Query data for all Event Care events. Mobile does not implement the Pusher private-channel protocol; it uses bounded polling after login plus pull-to-refresh and immediate post-mutation refetch, so stale local state is never treated as authoritative.

## Ownership rules visible in the UI

- Operational incidents are labeled **Organizer owned** and expose Organizer lifecycle actions.
- Technical incidents are labeled **PROWEM is handling this** and route the Organizer to the customer-visible support conversation.
- Ticket assignment, priority changes, internal notes and technical incident transitions are never exposed to the Organizer.
- Event Care does not duplicate scoring; Live Control explicitly keeps match scoring in PROWEM Core.

## Reset between rehearsals

Verify Payment, Start Event, resolutions and messages persist. Reset only a local/demo database when a pristine rehearsal is needed:

```bash
docker compose exec app php artisan migrate:fresh --seed --force
```
