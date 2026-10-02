# Screenshot Capture → AI Memory

Branch: `feature/screenshot-ai-memory`
Status: IMPLEMENTED (see implementation notes at the bottom)
Companion doc: `docs/GUIDES/AutoScreenshotCaptureJob.md`

## Goal

Let the user capture the screen they are currently looking at inside the app,
send it to a backend extraction API, and store the resulting text as a
retrievable "memory" that gets injected into future AI prompts.

## Decisions (confirmed)

| Question | Decision |
| --- | --- |
| What is "AI memory"? | New Drift table + Supabase table of text/image memories, retrieved and injected into future AI prompts |
| Screenshot source | In-app only, via `RepaintBoundary.toImage()` |
| Analysis backend | New agent-service endpoint; app uploads to Minio then calls it (mirrors `AIFoodCaloriesService`) |
| Platforms | iOS + Linux. Android explicitly out of scope for now |
| Backend | Owned by user — this repo provides the client, a local contract, and a stub |

## Non-goals

- Capturing other apps' screens (impossible on iOS without a Mac + Xcode
  instrumentation; not attempted).
- Screen recording / multi-frame capture.
- On-device OCR. Extraction is the backend's job.
- Vector/embedding search. v1 retrieval is recency + tag scoped. See
  "Deferred".

## Architecture

```
User taps capture
  -> CaptureService.capture(GlobalKey/BuildContext)
       RepaintBoundary -> ui.Image -> PNG bytes -> temp file
  -> ScreenshotMemoryService.captureAndRemember()
       1. MinioService.uploadFile(file, subFolder: '$personId/screenshots')
       2. POST {AGENT_URL}/analyze_screenshot_url {s3_url, route, width, height}
       3. Parse {summary, description, tags[], suggested_memory}
  -> AiMemoryDAO.insertMemory(...)  (local Drift, then pushToSupabase)
  -> Future AI calls: AiMemoryRetriever.buildContext(tags, limit) -> string
```

Layer placement follows the existing three-layer split:

- `data_layer/DataSources/local_database/Database.dart` — `AiMemoriesTable`
- `data_layer/DataSources/local_database/daos/ai_memories_dao.dart` — DAO
- `link_layer/storage_services/minio_service.dart` — already exists, reuse
- `orchestration_layer/Services/ScreenshotMemoryService.dart` — new, the
  orchestrator (HTTP + upload + DB write)
- `orchestration_layer/ReactiveBlock/Memory/AiMemoryBlock.dart` — new, signals
  for the UI, mirrors `ReactiveBlock/User/ContentBlock.dart`
- `sensor_layer/ui_layer/memory_page/` — capture button + memory browser list

## Data model

New table `ai_memories`, drift schemaVersion 75 -> 76.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | text | UUID v7, matches `IDGen.UUIDV7()` |
| `tenant_id` | text | `DEFAULT_TENANT_ID` like other tables |
| `person_id` | text | nullable, indexed |
| `title` | text | short label, agent-supplied or user-edited |
| `content` | text | the extracted memory text. This is what gets injected. |
| `summary` | text | one-line, used in list previews |
| `tags` | text | JSON array string, same approach as existing nullable metadata |
| `source_image_url` | text | public Minio URL of the PNG |
| `source_route` | text | logical route that was captured, e.g. `/health` |
| `ai_model` | text | which agent/model produced the extraction |
| `status` | text | draft / confirmed / discarded |
| `memory_weight` | real | 0..1 relevance score from the agent, default 1.0 |
| `created_at` / `updated_at` | datetime | `DateTimeUTCConverter()` |

`status` matters: v1 stores everything as `draft` and only `confirmed` rows
are injected into prompts. Without that gate every screenshot pollutes
context.

Migration SQL: `supabase/migrations/<timestamp>_ai_memories.sql`, cloned from
`20260502120000_ai_prompts.sql` — same UUID PK, same `person_id REFERENCES
auth.users ON DELETE CASCADE`, RLS policy `USING (auth.uid() = person_id)`,
`NOTIFY pgrst, 'reload schema'`.

Then register the table in the places `ai_prompts` already appears, or sync
silently breaks:

1. `@DataClassName('AiMemoryData')` + `class AiMemoriesTable extends Table`
2. `part 'daos/ai_memories_dao.dart';`
3. `tables: [ ... AiMemoriesTable ]` in `@DriftDatabase`
4. `daos: [ ... AiMemoryDAO ]`
5. `AiMemoryDAO get aiMemoryDAO => AiMemoryDAO(this);`
6. `schemaVersion => 76` + an `onUpgrade` branch
7. `SupabaseService` `tablesToSync` list
8. `SupabaseService._upsertToLocal` switch case
9. regenerate: `dart run build_runner build --delete-conflicting-outputs`

Note on the local file layout: `lib/data_layer/DataSources/local_database/database.dart`
is a symlink to `Database.dart` (case-insensitive-insensitive workaround). Edit
`Database.dart`; the symlink follows.

## Backend contract (client side, yours to implement)

Request:

```http
POST {AGENT_URL}/analyze_screenshot_url
Content-Type: application/json

{
  "s3_url": "https://.../person-id/screenshots/uuid.png",
  "route": "/health",
  "width": 1179,
  "height": 2556,
  "captured_at": "2026-09-30T10:12:33Z",
  "locale": "en",
  "person_context": "optional free text"
}
```

Response 200:

```json
{
  "output": {
    "title": "Resting heart rate trend",
    "summary": "Chart shows HR declining 72 -> 64 over 7 days.",
    "memory": "User tracks resting HR; recent trend is improving.",
    "tags": ["health", "heart-rate", "chart", "trend"],
    "memory_weight": 0.8
  },
  "intermediate_steps": []
}
```

Non-200 or malformed body must not throw into the UI — `AIFoodCaloriesService`
already models this with an outcome object carrying `requestOk`. Do the same:
`ScreenshotMemoryOutcome { AiMemoryData? memory, bool requestOk, String? error }`.

New env var, add to `.env.example` next to `FOOD_AGENT_URL`:

```
AGENT_URL=https://agent.icegate.icestore.art
```

Keep the existing `FOOD_AGENT_URL` default for the food flow. Do not rename it.

## Capture implementation notes

`RepaintBoundary.toImage()` requires the target to be laid out, painted, and
not inside a `RepaintBoundary` that is currently being composited. Practical
consequences:

- Wrap the captured subtree in a `RepaintBoundary` with a known
  `GlobalKey`. Do not try to capture the whole app — the root boundary
  usually fails or produces a blank/oversized image.
- `pixelRatio` must be explicit. `devicePixelRatio` on iOS can give large
  PNGs; clamp to something like `min(dpr, 3.0)`.
- Wait one frame after the tap before calling `toImage()`, otherwise
  transient state (dialogs mid-animation) gets baked in.
- Convert `ui.Image` -> PNG with `image.toByteData(format: ui.ImageByteFormat.png)`.
  There is no image-manipulation package in `pubspec.yaml` besides
  `image_picker`; PNG-encode in Flutter and let the backend handle
  resize/format. If the payload is regularly too big, add the `image` package
  then and downscale locally.
- Web is not a target, which is convenient: `toImage` on web is unreliable.

Capture should be initiated from a persistent overlay/button (a
`DynamicIsland`-style entry point like
`sensor_layer/ui_layer/canvas_page/CanvasDynamicIsland.dart`, or a
floating action in the shell) rather than being wired into 40 pages. One
capture point, one boundary, and pages opt in by being inside the shell.

## Retrieval / prompt injection

`AiMemoryRetriever.buildContext({List<String> tags, int limit = 5})` returns a
compact string block:

```
[User memory]
- User tracks resting HR; recent trend is improving. (health, heart-rate)
- Prefers dark dashboards with high contrast. (ui)
```

Query: `status = 'confirmed'`, `person_id = ?`, tag overlap when tags given,
ordered by `memory_weight DESC, updated_at DESC`, limit N.

Consumption point: the prompt that already exists for the AI features —
`AiPromptsDAO.getPrompt(personID, model)` as used in
`sensor_layer/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart:332`.
Inject the memory block above the user prompt, not inside it, so the stored
prompt stays user-authored and clean.

## i18n

Add keys to both `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`, then
regenerate `app_localizations*.dart`. Do not hand-edit the generated
`_en.dart` / `_vi.dart` files. Keys needed:
`screenshot_memory_capture`, `screenshot_memory_uploading`,
`screenshot_memory_analyzing`, `screenshot_memory_saved`,
`screenshot_memory_failed`, `screenshot_memory_empty`,
`screenshot_memory_confirm`, `screenshot_memory_discard`,
`screenshot_memory_prompt_to_capture`.

## Work breakdown

1. Schema + migration + DAO + Supabase registration; regenerate; verify
   `flutter analyze` clean and app launches.
2. Local contract folder with a stub server so the client is developable
   before the real API exists. See below.
3. `ScreenshotMemoryService` (upload + call + parse + persist).
4. `AiMemoryBlock` (signals: captureInFlight, latestMemory, list stream).
5. Capture button in the shell + capture boundary.
6. Memory browser page + route entry in `internal_route.dart` + confirm/
   discard actions.
7. `AiMemoryRetriever` + injection into the TalkSSH/AI prompt path.
8. l10n + analyze + build on iOS and Linux.
9. Tests: DAO CRUD, retriever ordering, outcome parsing against a fixture.

## Local stub for the API

The user is writing the extraction API. Until it exists, add
`tool/screenshot_agent_stub/` — a tiny Dart HTTP server (no dependencies
beyond `dart:io`) that serves `POST /analyze_screenshot_url` with a canned
`output` and, optionally, one that varies by `route` so the UI is testable.
Run with `dart run tool/screenshot_agent_stub/server.dart`, point `.env` at
it via `AGENT_URL=http://localhost:8123`. The service must read
`AGENT_URL` at call time, not at construction, so switching between stub and
prod is an env change only.

Keep the stub in `tool/` so it is excluded from the release app build and
cannot ship by accident.

## Risks / things to decide later

- **Payload size.** Full-resolution screenshots of dense pages can exceed
  agent request limits. Decide the downscale policy before shipping.
- **Prompt-injection from screen content.** Extracted text is derived from
  arbitrary on-screen content and will be re-injected into prompts. Treat it
  as untrusted: the retriever should wrap it in delimiters and the agent
  prompt should be told to treat it as context, not instructions. Worth doing
  from the start; retrofitting is annoying.
- **Storage growth.** One PNG per capture in Minio with no retention policy
  will accumulate. Add a retention sweep later; for now record
  `source_image_url` so images are reclaimable once memory is confirmed.
- **Sync-down cost.** Adding the table to `tablesToSync` means every full sync
  pulls all memories. Fine at first volume; add pagination or a
  `since` filter if it becomes slow.
- **Deferred: embeddings.** Keyword/tag retrieval is a placeholder for real
  semantic search. The `tags` + `memory_weight` columns are chosen so a
  later embedding column can be added without reshaping the table.

## Pre-existing issues noticed (not in scope, do not fix here)

- `SupabaseService.syncTableDown` hardcodes a `.eq('person_id', personId)`
  filter, so any memory table without `person_id` cannot use it. The new
  table has `person_id`, so it works — but the helper is not generic.
- `AiPromptsTable` is in the `tablesToSync` list but is commented out of the
  guest-migration table list at `Database.dart:2657`. Worth checking that is
  intentional.

## Implementation notes (added on implementation)

What the code does differently from the plan above, and why.

### Schema
The plan said 75 → 76 → 77 in two steps. Shipped as a single 75 → 77 jump with
both tables created in one `onUpgrade` branch, because nothing has been
released in between and one branch is simpler to reason about than two
sequential ones.

`ai_memories` and `capture_queue` both carry `person_id`, so
`SupabaseService.syncTableDown`'s hardcoded `.eq('person_id', ...)` filter works
without generalising that helper.

### Extraction: on-device first
`ScreenshotMemoryService.captureAndAnalyze` tries on-device captioning before
uploading. On iOS with a capable device this means the screenshot never leaves
the phone — which matters because iOS is also the platform where we can only
ever capture our own UI in the first place. The agent is the fallback.

The on-device path is `OnDeviceCaptionPlugin.swift` using FoundationModels.
Two constraints shaped it, both of which the original snippet ignored:

- `FoundationModels` requires iOS 26, but this project's deployment target is
  15.0. The import is `@_weakLink` and every call site is behind
  `#available(iOS 26.0, *)`, otherwise the app fails to link/run on the actual
  minimum target.
- It needs A17 Pro or M-series silicon. `isAvailable` checks
  `LanguageModelSession.availability`, not just the OS version, because a device
  can run a new iOS on older silicon.

The plugin file was added to all four relevant sections of
`ios/Runner.xcodeproj/project.pbxproj` (PBXBuildFile, PBXFileReference, group
membership, Sources build phase) — a new Swift file that is not registered there
does not compile and produces no error.

### Prompt injection
Injected into `TalkSSHPage` above the stored prompt, never merged into it, so
`ai_prompts.prompt` stays exactly what the user wrote. The injected block is
delimited and explicitly framed as untrusted, because it is derived from
arbitrary on-screen text — that boundary lives in
`AiMemoryDAO.renderContextBlock` rather than at each call site.

### Opt-in default
Enforced in three independent places on purpose, so no single failure turns
capture on: the `AiMemoryBlock` signal defaults to `false`; `loadSettings`
treats a missing or non-`true` config as off and stops the job; and the job
itself refuses to run without a boundary and consent. A user must actively flip
the switch.

I did not add a migration that seeds `auto_capture_enabled` rows. An earlier
attempt generated UUIDs in raw SQL, which was fragile and hard to read for no
benefit — the absent-config-means-off path already covers both fresh and
upgraded installs correctly.

### Budget
`countCreatedToday` counts `capture_queue` rows rather than tracking a counter,
so a restart cannot silently exceed the cap.

### What is not finished
- **Linux portal capture returns null by design.** The D-Bus transport in
  `linux/runner/portal_capture.cc` is wired up and handles consent, decline,
  and missing-daemon cases, but the success path (reading the returned `file://`
  URI and base64-encoding it for Dart) is deliberately not implemented rather
  than shipped untested. Linux therefore falls back to in-app capture until
  that is finished.
- **Android MediaProjection is untested on a device.** The Kotlin plugin and
  manifest entries are written but no hardware was available to exercise the
  consent flow or the `ImageReader` buffer-row-padding handling.
- **No real background execution.** `CaptureSyncJob` is a foreground
  `Timer.periodic`.
- Codegen for the drift changes was still running when this was written; see
  the commit message for whether `Database.g.dart` regenerated.
