# Ice Gate — API & integration reference

This document lists **network-facing integrations** used by the Flutter app: REST endpoints, SDK-backed APIs, and related environment variables. It is derived from the current codebase (not a guarantee that every backend route is implemented server-side).

---

## Environment variables (`.env`)

| Variable | Purpose |
|----------|---------|
| `BACKEND_URL` | Base URL for the Java/custom backend (`CustomAuthService`). Used as `{BACKEND_URL}/backend/...`. |
| `SUPABASE_URL` | Supabase project URL (`Supabase.initialize`). |
| `SUPABASE_ANON_KEY` | Supabase anonymous key. |
| `POWERSYNC_URL` | PowerSync replica WebSocket endpoint (`MyPowerSyncConnector`). |
| `FOOD_AGENT_URL` | Food vision / calorie agent base URL; client calls `POST {FOOD_AGENT_URL}/analyze_food_url`. Default in code: `http://localhost:8001`. |
| `USDA_API_KEY` | USDA FoodData Central API key. |
| `VNSTOCK_BASE_URL` | Custom market API base (defaults to `https://vnstock.finance.duylong.art` if unset). |
| `WAQI_TOKEN` | World Air Quality Index (WAQI / AQICN) token for AQI requests. |
| `S3_BUCKET`, `S3_REGION`, `S3_ENDPOINT`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_USE_SSL`, `S3_PORT` | S3-compatible storage for `MinioService` (meal images, etc.). |

Additional keys may exist in `.env` / `.env.example` for other experiments (e.g. `GEMINI_API_KEY`); they are not wired uniformly across the repo—search the codebase for `dotenv.env` when in doubt.

---

## 1. Custom Java backend (`BACKEND_URL`)

**Client:** `lib/orchestration_layer/Services/CustomAuthService.dart`  
All paths below are relative to `BACKEND_URL` (no trailing slash assumed).

| Method | Path | Body / notes |
|--------|------|----------------|
| POST | `/backend/auth/login` | JSON `{"userName": "<identity>", "password": "<password>"}` |
| POST | `/backend/auth/signup` | JSON registration payload |
| POST | `/backend/auth/logout` | Header `Authorization: Bearer <token>` |
| GET | `/backend/account/information` | Bearer token; current user |
| GET | `/backend/information/details` | Bearer token; person / profile details |
| POST | `/backend/information/edit` | Bearer token; profile fields passed as **query parameters** (e.g. `bio`, `location`, `university`, …) |
| GET | `/backend/person/skills` | Bearer token; returns list or `{ "skills": [...] }` |

**Multipart uploads** (`lib/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart`): base URL is `UserObjectResource.baseObjectUrl` (default **`https://backend.duylong.art`**, not `BACKEND_URL`).

| Method | Path | Notes |
|--------|------|--------|
| POST | `/backend/person/avatar/update` | Multipart field `file`; Bearer token |
| POST | `/backend/person/cover/update` | Same |
| POST | `/backend/person/app/upload` | General media when type is not avatar/cover |

**Public object URLs (read):** constructed as  
`{baseObjectUrl}/object/profiles/{userId}/avatars/avatar.png` and `.../covers/cover.png` (see same file).

---

## 2. Profile sync — `GET /api/v1/users/me`

**Client:** `lib/orchestration_layer/ReactiveBlock/User/PersonBlock.dart` (`appSync`)  
**Base URL:** hardcoded `https://backend.duylong.art` (not `BACKEND_URL`).  
**Request:** `GET /api/v1/users/me` with `Authorization: Bearer <supabase_access_token>`.  
**Use:** updates local DB with `profileImageUrl` / `coverImageUrl` when present.

---

## 3. Passkey hub (WebAuthn helper)

**Base:** `https://passkey.duylong.art/v1` (fixed in `CustomAuthService`).

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/login/begin` | JSON `{"email": "<email>"}` → returns `{ "publicKey": ... }` for the client |
| POST | `/login/finish` | JSON `{"email", "data": <credentialMap>}` |
| POST | `/register/begin` | JSON `{"email", "user_id"}` |
| POST | `/register/finish` | JSON `{"email", "user_id", "data": <credentialMap>}` |

---

## 4. Food AI agent

**Client:** `lib/orchestration_layer/Services/Health/AIFoodCaloriesServices.dart`  
**Endpoint:** `POST {FOOD_AGENT_URL}/analyze_food_url`  
**JSON body:** `s3_url`, `volume_cm3`, `food_name` (see `docs/PROTOCOLS/FoodAI.md`).

Images are uploaded first via **`MinioService`** (S3 API), then the **public HTTPS URL** is sent to the agent.

---

## 5. USDA FoodData Central

**Client:** `lib/orchestration_layer/Services/Health/FoodDataCentralService.dart`  
**Base:** `https://api.nal.usda.gov/fdc/v1`  
**Endpoint:** `GET /foods/search?api_key={USDA_API_KEY}&query=...&pageSize=1`

---

## 6. Market / finance (`VNSTOCK_BASE_URL`)

**Client:** `lib/sensor_layer/ui_layer/finance_page/services/market_service.dart`

| Method | Path |
|--------|------|
| GET | `/market/gold` |
| GET | `/market/index/historical?symbol=<symbol>` |
| GET | `/forex/historical?symbol=<symbol>` |
| GET | `/crypto/historical?symbol=<symbol>` |
| GET | `/market/indices` |

Responses are cached ~5 minutes in memory.

**Other finance code:** `FinanceService` is **static mock data** (no HTTP). `StockService` remote methods are **stubbed** (return null / empty).

---

## 7. Weather & air quality

**Client:** `lib/link_layer/environmental_block/EnvironmentalService.dart`

| Provider | URL pattern |
|----------|-------------|
| Open-Meteo | `https://api.open-meteo.com/v1/forecast?latitude=...&longitude=...&current=temperature_2m,weather_code` |
| WAQI | `https://api.waqi.info/feed/geo:{lat};{lon}/?token={WAQI_TOKEN}` |

---

## 8. Notion API

**Version header used in app:** `Notion-Version: 2022-06-28`

| Endpoint | Used in |
|----------|---------|
| `POST https://api.notion.com/v1/search` | `DocumentationBlock` — workspace search |
| `POST https://api.notion.com/v1/databases/{databaseId}/query` | Query database rows |
| `GET https://api.notion.com/v1/blocks/{blockId}/children` | Page block tree |
| `POST https://api.notion.com/v1/pages` | `NoteExportService` — create page in database |
| `PATCH https://api.notion.com/v1/blocks/{pageId}/children` | Append extra paragraph blocks (large notes) |

Auth: `Authorization: Bearer <integration_secret>` (user-provided / stored in app settings).

---

## 9. Google APIs

**Google Drive** — `lib/data_layer/Services/cloud/GoogleDriveService.dart`  
Uses **`google_sign_in`** + **`googleapis`** `DriveApi` (REST behind the SDK). Scopes include `drive.file` and metadata read-only.

**Google Docs (note export)** — `lib/link_layer/note_export/note_export_service.dart`  
Uses **`googleapis`** `DocsApi` after Google Sign-In with Docs/Drive scopes.

OAuth client IDs are defined in those files (platform-specific web vs Darwin).

---

## 10. YouTube

**Client:** `lib/data_layer/Services/YoutubeService.dart`  
Uses **`youtube_explode_dart`** (scrapes public player/metadata). **Not** the official YouTube Data API v3 unless you add it separately.

---

## 11. Huawei Cloud OAuth

**Client:** `lib/sensor_layer/phone_sensor/HuaweiCloudService.dart`  
**Token endpoint:** `POST https://oauth-login.cloud.huawei.com/oauth2/v3/token`  
Body: `application/x-www-form-urlencoded` with `grant_type=client_credentials`, `client_id`, `client_secret`.

---

## 12. Object storage (S3-compatible)

**Client:** `lib/link_layer/storage_services/minio_service.dart`  
Uses the **`minio`** Dart package against `S3_*` env vars. **No single HTTP “REST doc”** — it is the AWS S3-style API (`putObject`, `fPutObject`, etc.). Public URLs are built for AWS-style endpoints or generic `http(s)://endpoint/bucket/key`.

---

## 13. Supabase

**Initialization:** `lib/data_layer/initial_layer/DataLayer.dart` — `Supabase.initialize` with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

The app uses **`supabase_flutter`** for auth session, Postgres via the client (tables/RPC/storage as implemented in DAOs and services). **Concrete table and RPC names** are not duplicated here; see `supabase/schema_remote_snapshot.sql` for the database shape.

**Insights RPC (after migration):** `get_health_steps_trend(p_days int)` — daily `steps` / `calories_burned` from `health_metrics` for `auth.uid()`. Defined in `docs/MIGRATIONS/migration_v46_health_insights_rpc.sql`; called from `HealthInsightsRemoteService`.

---

## 14. PowerSync

**Connector:** `lib/link_layer/cloud_database/powersync_connector.dart`  
Credentials: `PowerSyncCredentials(endpoint: POWERSYNC_URL, token: Supabase access token, userId: ...)`.  
Upload hook currently **completes transactions without pushing** to a custom backend (outbox cleared locally); replication behavior may evolve.

---

## 15. Commented / legacy

- `CustomAuthService`: commented-out `GET /backend/person/app_sync` — not active.

---

## Maintenance notes

- **`BACKEND_URL` vs hardcoded `https://backend.duylong.art`:** profile images and `PersonBlock.appSync` use fixed hosts in some places; align env and constants if you change deployment targets.
- **Security:** never commit real `.env` secrets; rotate keys if they were exposed in version control.
