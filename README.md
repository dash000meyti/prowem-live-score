# PROWEM Event Care

Monorepo for **Event Care**: operational readiness, incidents, technical escalation, support SLAs, audit timelines, realtime updates, and post-event reporting.

```text
apps/api    Laravel 13 API (PostgreSQL, Redis, Sanctum, Reverb)
apps/web    Next.js App Router UI
apps/mobile Flutter mobile client (feature-oriented)
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

## Container layout

Each application owns its build:

```text
apps/api/Dockerfile        Laravel development and production targets
apps/web/Dockerfile        Next.js development and production targets
apps/mobile                Flutter app with feature-oriented layers
compose.yaml               Local development stack
compose.prod.yaml          Immutable demo/production stack
deploy/nginx               Public HTTP and WebSocket gateway
deploy/scripts/deploy.sh   Build, migrate and deploy workflow
```

The production stack exposes only the gateway. PostgreSQL and Redis remain on
an internal Docker network, and neither application installs dependencies at
container startup.

## Run locally

```bash
cp apps/api/.env.example apps/api/.env
docker compose up -d --build
docker compose exec app php artisan key:generate
docker compose exec app php artisan migrate:fresh --seed --force
```

`migrate:fresh` wipes the Event Care database. Use it only for local/demo resets.

After the initial build, dependency changes require rebuilding the owning image:

```bash
docker compose build app web
docker compose up -d
```

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

The presenter-ready multi-persona walkthrough is in [docs/demo-script.md](docs/demo-script.md). The detailed screen/API mapping remains in [docs/vertical-slice-demo.md](docs/vertical-slice-demo.md).

## Deploy

See [docs/deployment.md](docs/deployment.md) for the demo/production deployment
workflow, environment variables, update procedure and service URLs.
