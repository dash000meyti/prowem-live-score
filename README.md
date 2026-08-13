# PROWEM Event Care

Monorepo for **Event Care**: operational readiness, incidents, technical escalation, support SLAs, audit timelines, realtime updates, and post-event reporting.

```text
apps/api    Laravel 13 API (PostgreSQL, Redis, Sanctum, Reverb)
apps/web    Next.js App Router UI
```

The API is the source of truth. The web app does not recalculate readiness scores, SLA state, or ranking.

## Ports

| Service | Address |
|---|---|
| Web | http://127.0.0.1:3000 |
| API | http://127.0.0.1:18090/api/v1 |
| Health | http://127.0.0.1:18090/api/v1/health |
| OpenAPI | http://127.0.0.1:18090/docs/api |
| Reverb | ws://127.0.0.1:18091 |

## Run locally

```bash
cp apps/api/.env.example apps/api/.env
docker compose up -d --build
docker compose exec app php artisan key:generate
docker compose exec app php artisan migrate:fresh --seed --force
```

`migrate:fresh` wipes the Event Care database. Use it only for local/demo resets.

Web is served by the Compose `web` service. To run Next on the host instead:

```bash
pnpm install
API_INTERNAL_URL=http://127.0.0.1:18090 pnpm dev
```

## Demo credentials

Password for all seeded users: `password`

- `organizer@prowem.test`
- `support@prowem.test`
- `lead@prowem.test`
- `admin@prowem.test`

See [apps/api/docs/demo-data.md](apps/api/docs/demo-data.md) and [apps/api/docs/mobile-api-contract.md](apps/api/docs/mobile-api-contract.md).
