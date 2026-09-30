# Auto Screenshot Capture Job (cross-app behaviour observation)

Branch: `feature/screenshot-ai-memory`
Status: PARTIALLY IMPLEMENTED — see "Implementation notes" at the bottom
Companion doc: `docs/GUIDES/ScreenshotAIMemory.md`

## Goal

A foreground-only job that periodically captures what the user is looking at,
queues captures locally, and syncs them on a background cadence for later
extraction into AI memory. User reviews queued captures and confirms them.

## Platform reality — read this first

The request was "capture cross-app screenshots on all platforms." iOS cannot
do this and no amount of engineering changes that.

| Platform | Cross-app pixels | Mechanism | Status |
| --- | --- | --- | --- |
| Android | Yes | `MediaProjection` + `createVirtualDisplay`, consent prompt per session | Buildable |
| Linux | Yes | `xdg-desktop-portal` Screenshot, or direct X11 capture | Buildable |
| iOS | **No** | — | **Impossible for a third-party app** |

iOS exposes no API to read another app's pixels. Not a permission, not a
plist key, not an entitlement. The only routes are a jailbroken device or a
separate macOS process using `ScreenCaptureKit` / `CGWindowListCreateImage` —
capture happens on the Mac, and App Store review is a genuine risk for a
screen recorder of arbitrary content.

**What iOS does get:** the app already ships `IceGateScreenTimePlugin` in
`ios/Runner/AppDelegate.swift`, using `FamilyActivitySelection` +
`ManagedSettingsStore` on the `duylong.art/screentime` channel. That yields
per-app *activity events* — which app, when, for how long — with no pixels.
This is a real signal and it is already wired. It feeds the "importance"
scoring and the memory text, but it cannot produce a screenshot.

So on iOS the feature degrades to: app-usage context recorded, screenshot
captured for in-app screens only via `RepaintBoundary`. Honest framing for
the user-facing settings copy is "screenshots of other apps are not available
on iOS."

Do not silently substitute. If the requirement is truly cross-app pixels
everywhere, the only honest path is a macOS companion app, which is a second
project and should be its own plan.

## Architecture

```
ActivityTrackerService (existing singleton, already a WidgetsBindingObserver)
  - updatePath(route)      : route changes from MainShell.dart:126
  - dwell time per route   : 1-minute Timer.periodic, already implemented
  - app lifecycle          : paused/resumed, already handled
        |
        |  new: emits BehaviourSignal events
        v
AutoCaptureJob  (foreground-only, single Timer.periodic)
  1. score signal          : is this worth a capture?
  2. budget check          : capturesToday < dailyCap
  3. platform dispatch     : CaptureProvider per platform
        |                    - RepaintCaptureProvider  (in-app, all platforms)
        |                    - MediaProjectionCaptureProvider (Android)
        |                    - PortalCaptureProvider (Linux)
        v
  4. persist locally       : capture_queue table (status=pending)
  5. PNG -> temp file -> MinioService.uploadFile()
        |
        v
SyncJob  (background cadence, 15 min)
  - drain pending queue
  - POST {AGENT_URL}/analyze_screenshot_url
  - insert ai_memories row (status=draft)
  - user reviews in memory page -> status=confirmed
```

Layer placement follows the existing three-layer split:

- `orchestration_layer/Services/AutoCaptureJob.dart` — new, the timer + scoring
- `orchestration_layer/Services/CaptureSyncJob.dart` — new, the queue drainer
- `link_layer/capture/capture_provider.dart` — new, abstract provider
- `link_layer/capture/repaint_capture_provider.dart` — all platforms
- `link_layer/capture/media_projection_capture_provider.dart` — Android
- `link_layer/capture/portal_capture_provider.dart` — Linux
- `orchestration_layer/ReactiveBlock/Memory/AiMemoryBlock.dart` — signals, UI
- `sensor_layer/ui_layer/memory_page/` — queue + review UI
- `DataSources/local_database/Database.dart` — `capture_queue` table

## Reuse of existing code

`ActivityTrackerService` is the single natural trigger source. It is already:

- a singleton with `WidgetsBindingObserver`
- fed every route change (`MainShell.dart:126` calls `updatePath`)
- accumulating dwell time on a 1-minute timer
- gated on non-Guest login (`_scoreBlock!.username.value == 'Guest'` returns
  early) — reuse that exact guard, so Guest users are never captured

Add a `Stream<BehaviourSignal>` or a signals-based callback rather than a
second observer. Do not add another `WidgetsBindingObserver`; two observers
drifting out of sync is a bug waiting to happen.

`SocialBlockerBlock` already owns the `duylong.art/screentime` MethodChannel
and the app blacklist, so iOS app-usage data can be read from there without
touching Swift — check whether it already receives `DeviceActivityEvent`
activity events and surface them, rather than adding a second native path.

## Importance scoring

The user did not pin down a single rule, so scoring is a weighted sum of
signals with each weight independently tunable and each rule individually
disableable. This keeps it from being a black box.

| Signal | Source | Default weight |
| --- | --- | --- |
| Dwell time on route | `ActivityTrackerService` (already tracked) | 0.4 |
| Route on high-value allowlist | static config | 0.3 |
| User data-entry event on screen | provider signal from the shell | 0.2 |
| First visit to route this session | job-internal state | 0.1 |
| App is on the iOS blacklist (social) | `SocialBlockerBlock` | 0.5 |
| Repeated route visits (>3) in session | job-internal state | 0.2 |

Dwell time needs care: the existing tracker only flushes on 1-minute
boundaries, so sub-minute dwell is invisible. Either raise tracker resolution
to ~10s or accept a coarse signal. Lowering the interval means more DB writes
into `app_usage_history` — measure before changing it.

Threshold default: 0.6. Both signals and threshold live in `ConfigsTable`
(user-tunable) with code defaults, so scoring changes ship without an app
release.

## Budget

Hard local cap, default 10 captures/day, user-tunable 1–50. Enforced in
`AutoCaptureJob` before any capture call:

```
if (countPendingToday() >= dailyCap) skip;
```

Count `capture_queue` rows created today rather than keeping a counter in
memory — a counter resets on app restart and silently exceeds the budget.
Persist the daily count via a `COUNT(*) WHERE created_at >= startOfToday`.

Global opt-in toggle, **default off**, stored in `ConfigsTable` under a key
like `auto_capture_enabled`. This is surveillance-adjacent behaviour and must
not be on without the user asking for it. Enforce the default-off in the
migration, not just in the block, so a fresh install and an upgraded one
behave identically.

The existing `SettingWidget` already uses `Switch.adaptive` at line 329 —
follow that pattern for the settings entries.

## Local queue table

New table `capture_queue`, drift schemaVersion 76 -> 77 (chained after
`ai_memories` in the companion plan).

| Column | Type | Notes |
| --- | --- | --- |
| `id` | text | UUID v7 |
| `person_id` | text | indexed, required — sync filters on it |
| `source_kind` | text | `in_app` / `android_projection` / `linux_portal` |
| `app_label` | text | foreground app name; equals route for `in_app` |
| `route` | text | nullable, for `in_app` captures |
| `image_url` | text | Minio URL, set after upload |
| `local_path` | text | nullable fallback if upload failed |
| `score` | real | the computed importance score |
| `score_reasons` | text | JSON array of contributing signals, for debuggability |
| `status` | text | `pending` / `uploading` / `analyzed` / `failed` |
| `attempts` | int | retry counter, default 0 |
| `error` | text | nullable last failure message |
| `created_at` / `updated_at` | datetime | `DateTimeUTCConverter()` |

Store `score_reasons` as JSON. When a user asks "why did the app capture
this?", the answer should be readable rather than reconstructed from
guesswork.

Retries: exponential backoff, max 3 attempts, then `status=failed`. A failed
row stays visible in the review UI so it is not silently lost. Reset
`attempts` on app restart so a crash loop cannot permanently poison a row.

## Sync job

15-minute `Timer.periodic`, foreground only per the decision. Not a real OS
background job — on iOS a background timer is not something you can rely on,
and on Linux the app dies when the window closes. If true background
operation is needed later, that is a separate piece of native work per
platform and should be its own plan.

Drain loop must be reentrancy-safe: a 15-minute timer can overlap a slow
upload. Use a `bool _draining` guard, or the same row gets uploaded twice and
`analyze_screenshot_url` is billed twice.

Prefer `AGENT_URL` read at call time (see companion plan) so the stub server
can be swapped in.

## Provider abstraction

```dart
abstract class CaptureProvider {
  bool get isSupported;
  Future<bool> requestConsent();          // one-time per session on Android
  Future<CaptureResult?> capture();
}

class CaptureResult {
  final Uint8List pngBytes;
  final String sourceKind;
  final String appLabel;
  final String? route;
}
```

`isSupported` returns false on iOS for anything but `in_app`. The job checks
it and degrades silently rather than throwing — a user on iOS should get app
events, not errors.

### Android — MediaProjection

`MediaProjectionManager.createScreenCaptureIntent()`, user consents per
session. A foreground `Service` owns the `MediaProjection` and an
`ImageReader` on the virtual display; convert to PNG off the UI thread.
Reuse `android/app/src/main/kotlin/duylong/art/ice_gate/MainActivity.kt` as
the registration point for a new `duylong.art/mediaprojection` channel.

MediaProjection does not survive a reboot or app restart — the consent intent
cannot be persisted. Re-request on every cold start. This is a hard platform
behaviour, not a bug to engineer around.

### Linux — desktop portal

Prefer `xdg-desktop-portal` `org.freedesktop.portal.Screenshot` (XDG
standard, works under Wayland and X11). Under pure X11 without a portal
daemon, fall back to X11 root-window capture in
`linux/runner/my_application.cc`.

Add the GTK/portal dependencies to `linux/CMakeLists.txt` — note that file
already carries a `-Wno-deprecated-literal-operator` workaround for
`flutter_secure_storage_linux` + clang 20, and that build has
`-Wall -Werror`, so new native code must compile warning-free.

Wayland prevents unrestricted root capture by design. The portal handles
that correctly (it may prompt, and may decline). Treat a decline as a normal
no-capture, never as an error.

### All platforms — in-app RepaintBoundary

As described in the companion plan: one `RepaintBoundary` + `GlobalKey` in
the app shell, wait one frame post-signal, clamp `pixelRatio`. This is the
only provider that works on iOS.

## Consent and disclosure

This feature records what the user is doing across their apps. That carries
real obligations regardless of the fact that the user is also the developer:

- Off by default, explicit opt-in, with the toggle reachable in settings
- Consent prompt on first Android capture session (MediaProjection requires
  it; make ours explicit too)
- Plain-language disclosure of what is captured, how often, where stored, and
  how long retained
- A one-tap "delete all captures" in settings
- The queue review UI shows every capture before it becomes AI memory

Do not ship this silently. The default-off requirement in the Budget section
is not a formality.

## Work breakdown

1. `capture_queue` table + migration + DAO + 9-point Supabase registration;
   regenerate; `flutter analyze` clean
2. `configs` keys: `auto_capture_enabled` (default false), `auto_capture_daily_cap`
   (default 10), `auto_capture_threshold` (default 0.6)
3. `CaptureProvider` abstraction + `RepaintCaptureProvider` (works everywhere
   first, proves the pipeline end to end)
4. `AutoCaptureJob` timer + scoring + budget, driven by `ActivityTrackerService`
5. Queue + `CaptureSyncJob` drainer, reentrancy-guarded
6. Review UI in `memory_page` (list, confirm, discard, delete-all)
7. Settings entries in `SettingWidget` — opt-in, cap, threshold
8. Android `MediaProjection` provider + Kotlin service
9. Linux portal provider + native wiring + CMake deps
10. iOS app-event ingestion from `SocialBlockerBlock` (no pixels — events only)
11. l10n keys (en + vi), `flutter analyze`, builds on Android and Linux
12. Tests: scoring, budget enforcement across restarts, reentrancy guard,
    provider `isSupported` matrix

## Risks

- **Platform asymmetry is a product problem, not just an engineering one.**
  Two of three platforms capture pixels, one does not. Settings copy and any
  "AI knows what you're doing" claims must reflect the actual device.
- **Payload volume.** 10 full-res PNGs/day on a multi-platform user is real
  storage and real agent cost. Decide the downscale policy and whether
  captures below the threshold are ever kept locally.
- **Prompt injection.** Screen content is arbitrary and gets re-injected into
  prompts as context. Delimit it, instruct the agent to treat it as data not
  instructions. Do this from the first commit.
- **Timer overlap on drain** — the reentrancy guard is not optional.
- **`app_usage_history` write volume** if dwell resolution is lowered.
- **Linux portal absence** on bare X11 — need the fallback path, and a
  graceful no-op when neither works.
- **Consent revocation.** If the user revokes the Android permission
  mid-session, capture must fail closed, not retry-loop.

## Deferred

- OS-level background execution (iOS gives no reliable timer; Linux dies with
  the window)
- On-device OCR or local filtering before upload
- Embedding-based retrieval — the `tags` / `memory_weight` columns in the
  companion plan's `ai_memories` table are shaped so this can be added
  without a schema reshape
- Dedup / near-duplicate capture suppression
- Retention sweep and Minio lifecycle policy

## Implementation notes (added on implementation)

### Platform reality, restated because it shaped the code
iOS cannot capture other apps' pixels. No API, permission, or entitlement
exists. `PortalCaptureProvider` and `MediaProjectionCaptureProvider` both
report `isSupported == false` there, and the job falls back to
`RepaintCaptureProvider`. The iOS contribution to behaviour observation is the
`FamilyActivitySelection` app-usage data already present in
`IceGateScreenTimePlugin`, which yields events but not pixels.

### What is wired
- `AutoCaptureJob` — 1-minute foreground timer, weighted scoring with recorded
  reasons, daily budget from a row count, reentrancy guard, opt-in gated.
- `CaptureSyncJob` — 15-minute drain, batched, reentrancy-guarded, marks rows
  failed when the local PNG is gone rather than retrying forever.
- Guest sessions are blocked at three points (`loadSettings`, `tick`, and an
  `isGuestSession` setter for the auth layer), mirroring the guard
  `ActivityTrackerService` already applies for scoring.
- Triggers come from `MainShell`, which already fed route changes to
  `ActivityTrackerService`; the job is fed alongside it rather than adding a
  second `WidgetsBindingObserver`. The capture `RepaintBoundary` wraps the
  shell body.
- `AiMemoryBlock` + `AiMemoryPage` + a settings tile at `/ai-memory`.
- Scoring weights, threshold, and cap are config keys, so they can be tuned
  without a release.

### Not finished, deliberately
- **Linux portal success path.** `portal_capture.cc` implements the D-Bus
  transport, consent, user-dismissal, and no-daemon cases, but the success path
  (read the `file://` URI, base64 it to Dart) is left unimplemented rather than
  shipped untested. Linux currently degrades to in-app capture.
- **Android MediaProjection unverified on hardware.** Consent re-request,
  `createVirtualDisplay`, and `ImageReader` row-padding handling are written
  but untested. The row-padding crop in particular is the kind of thing that
  needs a real device to confirm.
- **iOS on-device captioning unverified on hardware** (needs iOS 26 +
  A17 Pro/M-series). The availability checks and `@_weakLink` import are in
  place so the app still builds and runs on the iOS 15 deployment target.
- **Dwell resolution.** The existing tracker flushes on 1-minute boundaries, so
  sub-minute dwell is invisible to scoring. Lowering it means more
  `app_usage_history` writes and was not done.
- No real OS background execution, no dedup of near-identical captures, no
  retention sweep, no embedding retrieval.
