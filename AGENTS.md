# Event Care

Monorepo: `apps/api` (Laravel 13 Event Care API) and `apps/web` (Next.js App Router).

The API is the source of truth for readiness, SLA, incident escalation, and event lifecycle. Do not reimplement those rules in the web app. Do not add Live Score tournament scoring or standings — Event Care only stores fixture/team projections.

## Run

From the repository root:

```bash
docker compose up -d
```

| Service | URL |
|---|---|
| Web | http://127.0.0.1:3000 |
| API | http://127.0.0.1:18090/api/v1 |
| Docs | http://127.0.0.1:18090/docs/api |
| Reverb | ws://127.0.0.1:18091 |

Artisan runs inside Compose: `docker compose exec app php artisan …`

Host Next (optional): `API_INTERNAL_URL=http://127.0.0.1:18090 pnpm dev`

## Demo users

Password `password`: `organizer@prowem.test`, `support@prowem.test`, `lead@prowem.test`, `admin@prowem.test`.

Contract: `apps/api/docs/mobile-api-contract.md`. Demo fixtures: `apps/api/docs/demo-data.md`.

## Auth

Sanctum bearer tokens. The web BFF stores the token in an httpOnly cookie and proxies `/api/v1` to Laravel. Never put the token in `localStorage`.
