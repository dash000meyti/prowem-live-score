# PROWEM Live Score

**Repository:** https://github.com/f-khosravii/prowem-live-score

Full-stack implementation of the **PROWEM Live Score take-home task**.

The project implements a real-time four-team round-robin football tournament with:

- a **Laravel / MySQL backend**
- **Redis + Laravel Reverb** for real-time updates
- a **Flutter mobile application**
- live score editing
- real-time standings recalculation
- animated standings movement when goals change ranking

---

## The Task

The requested application is a small live-score system for a football tournament.

Core requirements:

- exactly **4 teams**
- standard round-robin scheduling
- **3 rounds**
- **6 matches**
- PHP/MySQL backend
- validation and persistence of match results
- automatic calculation of:
  - points
  - goal difference
  - ranking
- API endpoints exposing matches and standings
- real-time updates
- a mobile client, with Flutter recommended
- visible standings animation when a score changes table order

This repository contains both the backend and mobile implementation.

---

## Repository Structure

```text
prowem-live-score/
├── backend/
│   ├── app/
│   ├── bootstrap/
│   ├── config/
│   ├── database/
│   ├── docker/
│   ├── public/
│   ├── routes/
│   ├── storage/
│   ├── tests/
│   ├── .env.example
│   ├── compose.yaml
│   ├── composer.json
│   ├── phpstan.neon.dist
│   └── README.md
│
├── mobile/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   ├── test/
│   ├── pubspec.yaml
│   └── README.md
│
└── README.md
```

The two applications are independent sibling projects.

Detailed documentation:

- [Backend documentation](backend/README.md)
- [Mobile documentation](mobile/README.md)

---

# Backend

## Technology

The backend uses:

- PHP 8.3
- Laravel 13
- MySQL 8.4
- Redis
- Laravel Reverb
- Nginx
- Docker Compose
- PHPUnit
- Larastan / PHPStan
- Laravel Pint

## Responsibilities

The backend is the source of truth for:

- tournament fixtures
- match state
- score validation
- match-state transitions
- standings
- live-match invariants
- concurrency protection
- REST API responses
- real-time tournament broadcasts

## Backend Architecture

The backend uses a lightweight layered Laravel architecture.

```text
HTTP
 │
 ▼
Controller
 │
 ├──────── READ ────────► TournamentReadService
 │                            │
 │                            ├── Eloquent reads
 │                            └── StandingsCalculator
 │
 └──────── WRITE ───────► UpdateMatchResult
                              │
                              ├── transaction
                              ├── row locking
                              ├── domain validation
                              ├── Eloquent mutation
                              ├── standings recalculation
                              └── TournamentUpdated
```

Controllers are intentionally thin.

Eloquent query logic is kept outside controllers.

Read operations are orchestrated by:

```text
TournamentReadService
```

Result mutations are orchestrated by:

```text
UpdateMatchResult
```

Reusable tournament logic is isolated in:

```text
StandingsCalculator
RoundRobinScheduler
```

The project intentionally does not introduce repository interfaces, CQRS infrastructure, event sourcing, or additional module frameworks because they would add unnecessary ceremony for this scope.

---

# Tournament Rules

The tournament contains exactly four teams:

```text
Juventus
Inter
AC Milan
AS Roma
```

A standard round robin produces:

```text
4 teams
3 rounds
2 matches per round
6 matches total
```

Fixtures are generated using the circle method rather than being hard-coded.

---

# Match State

Supported match states:

```text
scheduled
in_play
finished
```

Allowed result transitions:

```text
scheduled → in_play
scheduled → finished

in_play   → in_play
in_play   → finished

finished  → finished
```

A finished result may be corrected, but a finished match cannot return to live state.

---

## Live-Match Rule

A team may participate in at most one live match at a time.

Invalid:

```text
Juventus vs Inter      LIVE
Juventus vs AC Milan   LIVE
```

Valid:

```text
Juventus vs Inter      LIVE
AC Milan vs AS Roma    LIVE
```

The backend is authoritative for this rule.

---

# Standings

Standings are derived from match state and are not stored separately.

Matches counted toward standings:

```text
scheduled ❌
in_play   ✅
finished  ✅
```

Football scoring:

```text
win  = 3
draw = 1
loss = 0
```

Ranking:

```text
1. Points descending
2. Goal difference descending
3. Goals for descending
4. Team ID ascending
```

The final team ID comparison provides deterministic ordering when all football statistics are equal.

A real:

```text
0 - 0
```

is different from an unplayed match:

```text
NULL - NULL
```

---

# Backend API

All application endpoints are under:

```text
/api
```

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/api/tournament` | Full tournament snapshot |
| `GET` | `/api/matches` | Match list |
| `GET` | `/api/standings` | Current standings |
| `PATCH` | `/api/matches/{game}/result` | Update score/status |

Health endpoint:

```text
GET /up
```

Example mutation:

```http
PATCH /api/matches/1/result
Content-Type: application/json
```

```json
{
  "home_score": 2,
  "away_score": 1,
  "status": "in_play"
}
```

A successful mutation returns:

- synchronization metadata
- the confirmed match
- recalculated standings

---

# Real-Time Updates

Laravel Reverb provides the WebSocket transport.

Public channel:

```text
tournament
```

Event:

```text
tournament.updated
```

Conceptual event payload:

```json
{
  "update_id": "uuid",
  "occurred_at": "ISO-8601 timestamp",
  "match": {},
  "standings": []
}
```

Flow:

```text
Database transaction commits
        │
        ▼
TournamentUpdated
        │
        ▼
Redis queue
        │
        ▼
Queue worker
        │
        ▼
Laravel Reverb
        │
        ▼
Flutter clients
```

The HTTP response and WebSocket event generated by the same mutation share an `update_id`.

The mobile client uses this value for deduplication.

REST remains the source of truth. After reconnecting, the client refreshes `/api/tournament`.

---

# Concurrency

Result changes are treated as tournament-level mutations.

The backend uses:

- database transactions
- deterministic tournament locking
- `FOR UPDATE` on the target match
- live-team conflict checks
- standings recalculation inside the same transaction

This ensures that a match update and its returned standings describe one coherent tournament state.

---

# Database Integrity

MySQL also protects important persisted invariants.

Valid states:

```text
scheduled
in_play
finished
```

Score-state consistency:

```text
scheduled
→ both scores must be NULL

in_play / finished
→ both scores must be present
```

Examples:

```text
scheduled + NULL-NULL ✅
in_play + 0-0         ✅
finished + 2-1        ✅

scheduled + 1-0       ❌
in_play + NULL-NULL   ❌
finished + NULL-NULL  ❌
status = cancelled    ❌
```

---

# Mobile

## Technology

The mobile application uses:

- Flutter
- Dart
- Riverpod
- Dio
- `web_socket_channel`
- Laravel Reverb's Pusher-compatible WebSocket protocol

## Mobile Architecture

The Flutter application uses a feature-oriented structure:

```text
lib/
├── app/
├── core/
│   ├── config/
│   └── network/
│
└── features/
    └── tournament/
        ├── data/
        ├── domain/
        └── presentation/
```

Responsibilities:

- `core/config` — runtime environment configuration
- `core/network` — reusable HTTP/WebSocket infrastructure
- `data` — backend communication and realtime clients
- `domain` — tournament models
- `presentation` — Riverpod state, controller, screen, and widgets

---

# Mobile Behavior

The application supports:

- initial REST tournament loading
- six-match tournament display
- live score editing
- finishing matches
- correcting finished results
- standings display
- animated ranking changes
- one or two valid simultaneous live matches
- real-time external updates
- reconnect handling
- REST resynchronization
- HTTP/WebSocket update deduplication
- synchronization status feedback
- retry behavior after failures

---

# Animated Standings

A key task requirement is that standings visibly move when a goal changes ranking.

Rows are keyed by team identity and repositioned using Flutter animation.

Conceptually:

```text
goal update
    │
    ▼
backend recalculates standings
    │
    ▼
new standings received
    │
    ▼
row target positions change
    │
    ▼
animated row movement
```

---

# Local Development

## Backend

From the repository root:

```bash
cd backend
```

Create the local environment:

```bash
cp .env.example .env
```

Build and start services:

```bash
docker compose up -d --build
```

Initialize Laravel:

```bash
docker compose exec app composer setup
```

Check services:

```bash
docker compose ps
```

Expected services:

```text
app
mysql
nginx
queue
redis
reverb
```

---

## Local Ports

| Service | Address |
|---|---|
| Backend HTTP | `http://127.0.0.1:18080` |
| REST API | `http://127.0.0.1:18080/api` |
| Reverb | `ws://127.0.0.1:18081` |
| MySQL | `127.0.0.1:43106` |
| Redis | `127.0.0.1:6379` |

Quick backend check:

```bash
curl http://127.0.0.1:18080/up
curl http://127.0.0.1:18080/api/tournament
```

---

# Run Flutter on a Physical Android Device

Enter the mobile project:

```bash
cd mobile
```

Install dependencies:

```bash
flutter pub get
```

When using a physical Android device through USB:

```bash
adb reverse tcp:18080 tcp:18080
adb reverse tcp:18081 tcp:18081
```

Run:

```bash
flutter run \
  -d <device-id> \
  --dart-define=API_BASE_URL=http://127.0.0.1:18080/api \
  --dart-define=REVERB_HOST=127.0.0.1 \
  --dart-define=REVERB_PORT=18081 \
  --dart-define=REVERB_USE_TLS=false \
  --dart-define=REVERB_APP_KEY=<reverb-app-key>
```

The Reverb application key is intentionally client-visible.

Never embed:

```text
REVERB_APP_SECRET
```

inside Flutter.

---

# Testing and Quality

## Backend Quality Gate

From `backend/`:

```bash
docker compose exec app composer quality
```

It runs:

```text
Laravel Pint --test
        │
        ▼
Larastan / PHPStan level 8
        │
        ▼
PHPUnit
```

Individual commands:

```bash
docker compose exec app composer lint
docker compose exec app composer analyse
docker compose exec app composer test
```

Feature tests use a dedicated MySQL database:

```text
tournament_test
```

This is intentional because the application depends on MySQL behavior including constraints, transactions, and row locking.

---

## Mobile Quality

From `mobile/`:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

---

# Important Design Decisions

## REST is the source of truth

WebSockets optimize latency, not recovery.

A reconnect causes a fresh REST tournament snapshot to be loaded.

## Standings are not persisted

Matches are the source data.

Standings are a derived projection.

For four teams and six matches, recalculation is simple and avoids duplicated state.

## Ranking logic is backend-owned

Flutter accepts calculated standings from the backend instead of reimplementing football ranking rules in Dart.

## Controllers remain thin

Backend controllers contain HTTP concerns and delegate work to application dependencies.

Eloquent query logic is not placed directly inside controllers.

## No repository layer

A separate repository abstraction was intentionally avoided because Eloquent is sufficient for the persistence complexity of this task.

## Writes and reads have different orchestration

Reads use:

```text
TournamentReadService
```

Complex score mutations use:

```text
UpdateMatchResult
```

This keeps the design explicit without introducing a full CQRS architecture.

---

# Error Semantics

Transport/input validation errors use:

```text
HTTP 422
```

Domain-state conflicts use:

```text
HTTP 409
```

Examples of domain conflicts include:

- trying to return a finished match to `in_play`
- attempting to start a match when one of its teams is already playing another live match

Stable machine-readable error codes are returned for domain conflicts.

---

# Seeder Behavior

The backend seeder creates missing tournament teams and fixtures.

It intentionally preserves existing:

- scores
- match state
- team data

Safe repeat:

```bash
docker compose exec app php artisan db:seed
```

Intentional full reset:

```bash
docker compose exec app php artisan migrate:fresh --seed
```

Do not use `migrate:fresh` against data that must be preserved.

---

# Scope

Implemented:

- four-team round robin
- six generated fixtures
- live result updates
- result corrections
- real-time standings
- animated mobile ranking changes
- WebSocket updates
- reconnect recovery
- concurrency protection
- multiple disjoint live matches
- API validation
- database constraints
- automated backend and mobile tests

Intentionally outside scope:

- authentication
- team CRUD
- multiple tournaments
- player management
- substitutions
- yellow/red cards
- persisted standings
- historical goal-event timelines
- push notifications
- administrative dashboard
- complex tournament formats

---

# Production Considerations

This repository is a take-home implementation, not a complete production deployment.

For production, additional considerations would include:

- authentication and authorization
- HTTPS / WSS
- restricted WebSocket origins
- secret management
- rate limiting
- structured logging
- monitoring and observability
- queue monitoring
- CI/CD quality-gate execution
- audit history for score corrections
- backups and recovery
- explicit multi-tournament ownership
- horizontal Reverb scaling where necessary

---

# Detailed Documentation

Backend:

[backend/README.md](backend/README.md)

Mobile:

[mobile/README.md](mobile/README.md)
