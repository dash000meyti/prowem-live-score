# PROWEM Event Care API

Laravel 13 / PHP 8.3 API for event readiness, operational incidents, PROWEM technical escalation, support SLAs, audit timelines, real-time updates, and post-event reporting.

This app lives at `apps/api` in the Event Care monorepo. Run the stack from the repository root with `docker compose up -d`. See the [root README](../../README.md).

- API: `http://127.0.0.1:18090/api/v1`
- Health: `http://127.0.0.1:18090/api/v1/health`
- OpenAPI UI: `http://127.0.0.1:18090/docs/api`
- Reverb: `ws://127.0.0.1:18091`

## Demo credentials

All seeded users use password `password`:

- `organizer@prowem.test`
- `support@prowem.test`
- `lead@prowem.test`
- `admin@prowem.test`
- `other-organizer@prowem.test` (separate customer for authorization/isolation testing)

See [docs/demo-data.md](docs/demo-data.md) and [docs/mobile-api-contract.md](docs/mobile-api-contract.md).

## Quality

```bash
docker compose exec app php artisan test
docker compose exec app composer lint
docker compose exec app composer analyse
docker compose exec app php artisan scramble:export --path=storage/api.json
```

## Architecture decisions

- Core PROWEM tournament entities are local projections (`teams`, `fixtures`, `venues`, `referees`) with external references; Event Care does not implement tournament scheduling or standings.
- Readiness status and score are separate. Critical blocked checks always block status even when the numeric score is high.
- Technical incidents and their live-event escalation are one transaction. A PostgreSQL partial unique index prevents concurrent duplicate active incidents.
- Controllers contain HTTP concerns; Actions own transitions and transactional workflows; Resources own frontend contracts; centralized exception and response infrastructure owns envelopes.
