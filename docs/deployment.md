# Deployment

The deployment stack is defined independently in `compose.prod.yaml`. It builds
immutable Laravel and Next.js images and exposes one public gateway on port 80.

## Architecture

```text
Internet
   |
gateway :80
   |-- /app/*, WebSocket ---> reverb :8080
   |-- /docs/api, /up ------> api-nginx :80 ---> api :9000
   `-- everything else -----> web :3000 ---> api-nginx :80

api, queue, reverb ---> postgres + redis (internal network only)
```

The browser uses the Next.js BFF for `/api/v1` requests. The Sanctum bearer
token remains in an HTTP-only cookie and is never stored in browser storage.

## First deployment

Install Docker Engine with the Compose plugin, clone the repository, then:

```bash
cp .env.production.example .env.production
```

Generate values for `APP_KEY`, `DB_PASSWORD`, and `REVERB_APP_SECRET`:

```bash
printf 'base64:%s\n' "$(openssl rand -base64 32)"
openssl rand -hex 32
openssl rand -hex 32
```

Put those values in `.env.production`. Set `PUBLIC_URL`, `PUBLIC_HOST`, scheme,
WebSocket port and secure-cookie flag for the server's IP or domain.

For an HTTP demo by IP:

```dotenv
PUBLIC_URL=http://178.239.147.50
PUBLIC_HOST=178.239.147.50
PUBLIC_SCHEME=http
PUBLIC_REVERB_PORT=80
AUTH_COOKIE_SECURE=false
PUBLIC_API_DOCS=true
```

Deploy and seed the demo data once:

```bash
sh deploy/scripts/deploy.sh --seed
```

Do not use `migrate:fresh` during a normal deployment because it deletes all
application data.

## Updating

After pulling a new revision:

```bash
git pull --ff-only
sh deploy/scripts/deploy.sh
```

The script rebuilds changed images, starts infrastructure, runs forward-only
migrations, replaces changed services and prints their health status.

## Operations

```bash
docker compose --env-file .env.production -f compose.prod.yaml ps
docker compose --env-file .env.production -f compose.prod.yaml logs -f --tail=100
docker compose --env-file .env.production -f compose.prod.yaml exec api php artisan about
```

With the sample IP configuration:

- Web: `http://178.239.147.50/`
- API: `http://178.239.147.50/api/v1`
- Health: `http://178.239.147.50/api/v1/health`
- Docs: `http://178.239.147.50/docs/api`
- WebSocket: `ws://178.239.147.50/app/{key}`

When a domain is attached, terminate TLS at the gateway (or an upstream load
balancer), set the public scheme to `https`, WebSocket port to `443`, and
`AUTH_COOKIE_SECURE=true`, then rebuild the web image.
