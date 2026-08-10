# PROWEM Live Score Mobile

Flutter mobile client for the **PROWEM Full-Stack Live Score take-home task**.

The application displays a four-team round-robin football tournament, receives real-time score/standings updates, allows match result updates, and animates standings row movement when ranking changes.

The backend lives in the sibling directory:

```text
../backend
```

---

## The Task

The take-home task requires a full-stack live-score application with:

- exactly **4 teams**
- a standard round-robin tournament
- **3 rounds**
- **6 matches**
- a PHP/MySQL backend
- result validation and persistence
- real-time points, goal-difference, and ranking calculation
- API endpoints for match and standings updates
- a mobile client, with Flutter recommended
- real-time synchronization
- animated standings movement when goals change ranking

This Flutter application implements the mobile side of that task.

---

## Technology

| Concern | Technology |
|---|---|
| Framework | Flutter 3.44.x |
| Language | Dart 3.12.x |
| State management | Riverpod |
| HTTP client | Dio |
| WebSocket transport | `web_socket_channel` |
| Backend realtime | Laravel Reverb / Pusher-compatible protocol |

---

## Architecture

The mobile application uses a feature-oriented structure:

```text
lib/
├── app/
│   ├── app.dart
│   └── app_theme.dart
│
├── core/
│   ├── config/
│   │   └── app_config.dart
│   └── network/
│       ├── api_client.dart
│       └── web_socket_transport.dart
│
├── features/
│   └── tournament/
│       ├── data/
│       │   ├── reverb_tournament_realtime_client.dart
│       │   ├── tournament_api.dart
│       │   ├── tournament_realtime_client.dart
│       │   └── tournament_repository.dart
│       │
│       ├── domain/
│       │   ├── game.dart
│       │   ├── standing.dart
│       │   ├── team.dart
│       │   └── tournament_snapshot.dart
│       │
│       └── presentation/
│           ├── tournament_controller.dart
│           ├── tournament_providers.dart
│           ├── tournament_screen.dart
│           ├── tournament_state.dart
│           └── widgets/
│
└── main.dart
```

Responsibilities:

- **core/config** resolves runtime configuration from `--dart-define`.
- **core/network** contains reusable HTTP/WebSocket infrastructure.
- **data** talks to the REST API and Reverb.
- **domain** contains immutable tournament data models.
- **presentation** contains Riverpod state, orchestration, screens, and widgets.

The REST API is treated as the source of truth. Reverb provides low-latency incremental updates.

---

## Runtime Flow

Initial load:

```text
App starts
   │
   ▼
GET /api/tournament
   │
   ▼
TournamentSnapshot
   │
   ▼
Riverpod state
   │
   ▼
UI
```

Real-time operation:

```text
Laravel Reverb
   │
   ▼
tournament.updated
   │
   ▼
Realtime client
   │
   ▼
TournamentController
   │
   ▼
Match + standings state update
   │
   ▼
Animated UI
```

Reconnect recovery:

```text
WebSocket disconnect
   │
   ▼
Reconnect with backoff
   │
   ▼
REST resync
   │
   ▼
Fresh tournament snapshot
```

This prevents missed WebSocket events from permanently desynchronizing the client.

---

## HTTP + WebSocket Deduplication

A score mutation is confirmed by HTTP and also broadcast by the backend.

Both payloads contain the same:

```text
update_id
```

The mobile state controller tracks confirmed update IDs so the same logical mutation is not applied twice.

---

## Mutation Queue

Match mutations are serialized in the client.

Each user action is represented as a queued mutation and processed in order.

This prevents rapid user interactions from overwriting newer standings with an older HTTP response.

The backend remains authoritative; the queue is a client-side consistency mechanism.

---

## Multiple Live Matches

The backend permits two simultaneous live matches only when the matches involve disjoint teams.

The UI supports:

- zero live matches
- one live match
- two valid live matches

When two matches are live, both are displayed with independent score controls.

The UI may block an obviously invalid "start match" action when one of the teams is already live, but backend validation remains authoritative.

---

## Standings Animation

Standings rows are keyed by team ID and rendered with animated positioning.

When a goal changes ranking:

```text
old position
    │
    ▼
new standings order
    │
    ▼
AnimatedPositioned
    │
    ▼
row moves to new rank
```

This directly addresses the task requirement that standings visibly move when a score changes the table.

---

## UI States

The application distinguishes connection states such as:

```text
SYNCED
SYNCING
RECONNECTING
SYNC FAILED
```

A failed synchronization does not discard the last confirmed tournament snapshot.

Only the widgets affected by a state change subscribe to the relevant Riverpod state slices, reducing unnecessary whole-screen rebuilds.

---

## Match Result Editing

The result editor supports the lifecycle of a match.

Scheduled match:

```text
Start match
```

Live match:

```text
adjust home score
adjust away score
save
mark final
```

Finished match:

```text
correct result
```

The backend validates all state transitions.

---

## Configuration

Runtime configuration is supplied through `--dart-define`.

The application expects:

```text
API_BASE_URL
REVERB_HOST
REVERB_PORT
REVERB_USE_TLS
REVERB_APP_KEY
```

The Reverb application key is client-visible.

Never place the backend secret in Flutter:

```text
REVERB_APP_SECRET
```

---

## Local Backend

Start the backend first:

```bash
cd ../backend
docker compose up -d
```

The default local endpoints are:

```text
REST API:
http://127.0.0.1:18080/api

Reverb:
ws://127.0.0.1:18081
```

---

## Android Device over USB

For a physical Android device connected with ADB:

```bash
adb reverse tcp:18080 tcp:18080
adb reverse tcp:18081 tcp:18081
```

Then run the application:

```bash
flutter run \
  -d <device-id> \
  --dart-define=API_BASE_URL=http://127.0.0.1:18080/api \
  --dart-define=REVERB_HOST=127.0.0.1 \
  --dart-define=REVERB_PORT=18081 \
  --dart-define=REVERB_USE_TLS=false \
  --dart-define=REVERB_APP_KEY=<reverb-app-key>
```

Do not pass `REVERB_APP_SECRET`.

---

## Emulator / Other Environments

The API and WebSocket host values are intentionally configurable.

Use `--dart-define` values appropriate for the target environment rather than hard-coding development addresses in application code.

---

## Install Dependencies

```bash
flutter pub get
```

If your local Flutter installation is configured to use a package mirror, Flutter may display a message indicating where assets are downloaded from. That is environment-specific and not part of the application configuration.

---

## Quality Checks

Static analysis:

```bash
flutter analyze
```

Tests:

```bash
flutter test
```

Debug Android build:

```bash
flutter build apk --debug
```

These three commands should pass before submission.

---

## Tests

The mobile test suite covers important behavior including:

- initial tournament loading
- REST snapshot application
- external real-time updates
- WebSocket reconnect/resync
- update-ID deduplication
- rapid same-match mutations
- mutations across different matches
- failed mutation handling
- retry behavior
- live result correction
- finished result correction
- 0-0 as a real played result
- two simultaneous valid live matches
- standings movement behavior
- preservation of unaffected match widgets
- match promotion when another match is finalized
- scroll/state preservation

---

## Design Decisions

### REST remains the source of truth

WebSocket events are optimized for immediacy, not recovery.

A reconnect triggers a REST resync.

### Full standings are accepted from the backend

The backend owns ranking logic, so Flutter does not independently recalculate the competition table.

This avoids duplicated domain rules across PHP and Dart.

### Optimistic score mutation is avoided

The UI waits for backend confirmation before treating a result as confirmed.

This is appropriate because match-state transitions and simultaneous-live-match rules are server-side invariants.

### Mutations are serialized

HTTP responses can arrive at different times.

Serial processing avoids a stale response replacing a newer confirmed state.

### No backend secret is stored in the client

Only the public Reverb application key is required for the WebSocket connection.

---

## Scope

Implemented:

- tournament snapshot
- six-match display
- standings
- live match controls
- result correction
- real-time Reverb updates
- reconnect recovery
- standings animation
- multiple valid live matches
- synchronization feedback

Intentionally outside scope:

- authentication
- player management
- cards/substitutions
- multiple tournaments
- offline result submission
- persisted local tournament database
- push notifications

---

## Repository

```text
prowem-live-score/
├── backend/
└── mobile/
```

Backend documentation is available in:

```text
../backend/README.md
```
