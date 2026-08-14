# PROWEM Event Care presentation script

This walkthrough is intended for a local or isolated demo environment. All seeded users use the password `password`.

## Demo users

| Persona | Login | Role | Primary device | Primary scenario |
|---|---|---|---|---|
| Organizer | `organizer@prowem.test` | `organizer` | Mobile | `ALP-2026`, `MRC-2026`, `VSC-2026`, `SPR-2026` |
| PROWEM Support | `support@prowem.test` | `support_agent` | Desktop | `ZTC-2026` |
| Support Lead | `lead@prowem.test` | `support_lead` | Desktop fallback | Any support scenario |

Organizer Staff is not an implemented product role. The current authorization model has no safe scoped staff membership or operation grants, so Staff is hidden rather than simulated.

## Reset before presenting

Run only against the local/demo database:

```bash
docker compose exec app php artisan migrate:fresh --seed --force
```

Use external references rather than numeric IDs. Seed-relative dates and SLA timestamps keep the operational screens useful after every reset.

## Scene 1 — Fix readiness

User: Organizer  
Device: Mobile  
Event: `ALP-2026`

1. Sign in and open Alpine Youth Cup.
   Expected: **Event not ready** and the highest blockers appear before general context.
2. Open the Salzburg United payment blocker.
   Expected: Team Passport opens directly; Payment is above completed checks.
3. Choose **Verify Payment**, then confirm.
   Expected: the button is disabled while saving, Payment becomes Ready, the score change is shown, and Event readiness refetches without manual reload.

Narrative: Event Care turns a vague readiness percentage into a concrete operational action.

## Scene 2 — Start an eligible Event

User: Organizer  
Device: Mobile  
Event: `MRC-2026`

1. Open Munich Ready Cup.
   Expected: **Ready for kickoff**, no critical blockers, one primary **Start Event** action.
2. Start and confirm.
   Expected: the API performs `ready → live`; Event Home changes to match-day priorities.

Do not use `ALP-2026` for this step: it intentionally retains other blockers and the backend correctly rejects an early start.

## Scene 3 — Organizer-owned operations

User: Organizer  
Device: Mobile  
Event: `VSC-2026`

1. Open **Referee unavailable** from Needs Action Now.
   Expected: owner is **Your Event Team**, with Match #23, Field 3 and kickoff context visible.
2. Choose **Resolve issue**, enter `Backup referee confirmed.`, and confirm.
   Expected: the resolution persists and the Live Home action count decreases after return/refetch.

## Scene 4 — PROWEM-owned technical problem

User: Organizer  
Device: Mobile  
Event: `ZTC-2026`

1. Open **Streaming unavailable**.
   Expected: owner is **PROWEM Support**, P1 is visible, and no support-admin controls are shown.
2. Open the linked ticket `EC-ZTC-P1-001`.
   Expected: SLA/assignment and customer-visible conversation are shown. The seeded internal node-restart note is absent.

Keep this screen open for the multi-user handoff. Mobile uses immediate mutation refresh, pull-to-refresh and bounded polling as a reliable realtime fallback.

## Scene 5 — Support takes ownership

User: PROWEM Support  
Device: Desktop  
Event: `ZTC-2026`

1. Sign in using **Support Agent demo**.
   Expected: the entry screen is **Technical Support Queue** and live critical Events sort first.
2. Open Zurich Tech Critical Cup → Support Tickets.
   Expected: the active P1 is first, with customer, location, owner and SLA response state.
3. Open `EC-ZTC-P1-001`.
   Expected: support handling controls, conversation and clearly marked internal messages are visible.
4. Send a **Customer-visible reply**: `Failover is stable. We are completing final checks.`
   Expected: the message persists and becomes visible to the Organizer.
5. Resolve the linked technical Incident with `Streaming service restored and verified.` Then resolve the Ticket with the same customer-safe resolution.
   Expected: both real backend lifecycles are completed and broadcast.

## Scene 6 — Organizer sees the handoff complete

User: Organizer  
Device: Mobile  
Event: `ZTC-2026`

1. Return to or refresh the ticket conversation.
   Expected: the Support reply is visible, the Ticket is **Resolved**, and critical red styling has calmed to success styling.
2. Reopen the technical incident if desired.
   Expected: the persisted Incident resolution is visible.

## Scene 7 — Improve the next Event

User: Organizer  
Device: Mobile or Desktop  
Event: `SPR-2026`

1. Open PROWEM Spring Cup and choose **View Event Care report**.
   Expected: persisted kickoff readiness, operations, technical support, SLA performance, major blockers and deterministic recommendations are visible.

Close with: **Prepare → Monitor → Resolve → Improve.**

## Presentation safety notes

- `GCC-2026` is intentionally Cancelled and demonstrates calm/empty states.
- `SLOC-2026` is the deeper operational dataset if more Incident history is requested.
- `other-organizer@prowem.test` owns `PRIVATE-2026` and exists only to demonstrate account isolation.
- Reset after destructive rehearsal actions such as Verify Payment, Start Event, Incident resolution or Ticket resolution.
