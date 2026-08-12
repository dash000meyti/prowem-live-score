# PROWEM Event Care API

Laravel 13 / PHP 8.3 API for event readiness, operational incidents, PROWEM technical escalation, support SLAs, audit timelines, real-time updates, and post-event reporting. The app is isolated from the existing live-score backend and uses PostgreSQL 17, Redis, Sanctum, Reverb, and Dedoc Scramble.

## Run locally

```bash
cp .env.example .env
docker compose build
docker compose up -d postgres redis app
docker compose exec app php artisan key:generate
docker compose up -d
docker compose exec app php artisan migrate:fresh --seed --force
docker compose ps
```

> `migrate:fresh` deletes and recreates every table in the local Event Care database. Use this command only when resetting local/demo data.

- API: `http://127.0.0.1:18090/api/v1`
- Health: `http://127.0.0.1:18090/api/v1/health`
- OpenAPI UI: `http://127.0.0.1:18090/docs/api`
- OpenAPI JSON: `http://127.0.0.1:18090/docs/api.json`
- Reverb: `ws://127.0.0.1:18091`

Docs are public only in `local`; other environments require an authenticated admin. Event broadcasts use the private `events.{eventId}` channel. Queue and Reverb run as dedicated Compose services.

## Demo credentials

All seeded users use password `password`:

- `organizer@prowem.test`
- `support@prowem.test`
- `lead@prowem.test`
- `admin@prowem.test`
- `other-organizer@prowem.test` (separate customer for authorization/isolation testing)

The deterministic seed creates seven primary mobile scenarios plus a second-customer isolation scenario. See [docs/demo-data.md](docs/demo-data.md) for stable references, fresh-seed IDs, expected UI states, and pagination datasets.

## Demo scenarios

| Reference | Event | Status | Purpose |
|---|---|---|---|
| `VSC-2026` | Vienna Summer Cup 2026 | live | Primary readiness/incident/support flow |
| `ALP-2026` | Alpine Youth Cup 2026 | preparing | Critical blockers and drill-down |
| `MRC-2026` | Munich Ready Cup 2026 | ready | Start Event CTA |
| `SLOC-2026` | Salzburg Live Operations Cup | live | Operational-only control |
| `ZTC-2026` | Zurich Tech Critical Cup | live | P1/SLA/conversation |
| `SPR-2026` | PROWEM Spring Cup 2026 | completed | Historical report |
| `GCC-2026` | Graz Cancelled Cup | cancelled | Cancelled/empty states |
| `PRIVATE-2026` | Private Club Cup | preparing | Cross-customer isolation |

## Quality

```bash
docker compose exec app php artisan test
docker compose exec app composer lint
docker compose exec app composer analyse
docker compose exec app php artisan scramble:export --path=storage/api.json
```

PostgreSQL test database `event_care_test` is created by `docker/postgres/init/01-create-test-database.sql`. Important configuration is documented in `.env.example`; host ports default to HTTP `18090`, PostgreSQL `15432`, Redis `16379`, and Reverb `18091`.

## Architecture decisions

- Core PROWEM tournament entities are local projections (`teams`, `fixtures`, `venues`, `referees`) with external references; Event Care does not implement tournament scheduling or standings.
- Readiness status and score are separate. Critical blocked checks always block status even when the numeric score is high.
- Technical incidents and their live-event escalation are one transaction. A PostgreSQL partial unique index prevents concurrent duplicate active incidents.
- Controllers contain HTTP concerns; Actions own transitions and transactional workflows; Resources own frontend contracts; centralized exception and response infrastructure owns envelopes.
