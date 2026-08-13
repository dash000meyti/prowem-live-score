#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$ROOT_DIR"

compose() {
    docker compose --env-file .env.production -f compose.prod.yaml "$@"
}

compose build
compose up -d postgres redis
compose run --rm api php artisan migrate --force

if [ "${1:-}" = "--seed" ]; then
    compose run --rm api php artisan db:seed --force
fi

compose up -d --remove-orphans
compose ps
