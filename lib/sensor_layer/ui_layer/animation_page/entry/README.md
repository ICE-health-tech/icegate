# Ice Gate — Entry / Splash Module

Animated splash shown at cold start before the home shell. The user taps the logo (or auth completes) to play the **charge → shatter → route** exit into `/` or `/login`.

**Route:** registered in `InternalRoute` as the app entry child (`PrismEntryPage`).

**Import:**

```dart
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/entry/PrismEntryPage.dart';
// or barrel:
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/entry/entry.dart';
```

---

## Folder layout

```
entry/
├── README.md                 ← this file
├── entry.dart                ← barrel exports (optional)
├── PrismEntryPage.dart       ← orchestrator (controllers, auth, exit VFX)
└── components/
    ├── EntryConstants.dart   ← palette + layout tokens (also used app-wide)
    ├── EntryAtmosphere.dart  ← ice background gradients (CustomPainter)
    ├── EntryGeometry.dart    ← procedural shard / crack / particle data
    ├── PrismBackground.dart  ← stacks atmosphere + grid + snow + shards
    ├── PrismPainters.dart    ← all CustomPainters + model classes
    ├── TacticalGrid.dart     ← HUD grid wrapper
    ├── PremiumLogo.dart      ← alternate logo widget (petal burst)
    ├── PrismMainContent.dart ← composable background + logo (refactor target)
    ├── ShatterEffect.dart    ← shockwave / flash / shatter stack widget
    ├── EntryFlashEffect.dart ← white flash overlay
    ├── IcePetalBurst.dart    ← logo charge petals
    ├── IceGateStoryboard.dart← 10-phase exit timeline helpers (Rive-ready)
    ├── AuthStatusPulse.dart  ← loading dot under logo
    ├── AuthErrorHelper.dart  ← maps AuthBlock error keys → l10n
    └── ScanningStatusOverlay.dart
```

**Backward-compatible re-exports** (do not add new code here):

- `animation_page/PrismEntryPage.dart`
- `animation_page/components/EntryConstants.dart`
- `animation_page/components/AuthErrorHelper.dart`

---

## Render stack (bottom → top)

`PrismEntryPage` builds a `Stack`:

| Layer | Source | Role |
|-------|--------|------|
| Scaffold fill | `HealthMetricColors.iceBgMid` | Base while painters load |
| Charge pulse | `IceGateChargePulsePainter` | Pointer-reactive ring before exit |
| Main scene | `PrismBackground` | Atmosphere, tactical grid, snow, assembling shards |
| Logo | `_buildPremiumLogo()` | Asset + glow; tap triggers exit |
| Exit VFX | `ShockwavePainter`, `IceFlashPainter`, `GlassShatterPainter` | Shatter on route change |
| Flash | White `Container` | Brief fade at end of crack animation |

### `PrismBackground` internals

1. **EntryAtmosphere** — glacial linear base + frost radial bloom + breathing beacon  
2. **TacticalGrid** — parallax grid, HUD rings, scan line, soft vignette  
3. **SnowfallOverlay** — shared widget, `snowOpacity` prop (default `0.14` on entry)  
4. **PrismPainter** — shards fly inward during `_assemblyController` (1.4s)

---

## Animation controllers

| Controller | Duration | Purpose |
|------------|----------|---------|
| `_assemblyController` | 1400 ms | Shard assembly; sets `_isAssemblyDone` |
| `_pulseController` | 3 s (repeat) | Logo breathe / atmosphere beacon |
| `_auroraController` | 12 s (repeat) | Drifting frost pools |
| `_scanController` | 10 s (repeat) | Tactical grid scan line |
| `_spinController` | 4 s (repeat) | Logo slow rotation |
| `_chargeController` | 400 ms | Pre-exit charge pulse |
| `_crackController` | 2100 ms | Shatter + fade + navigation |

**Exit flow (`_playElegantExit`):** charge → heavy haptic → crack forward → wait ~1.2s → `context.go('/')` if authenticated else `/login`.

**Auth:** `effect()` on `AuthBlock.status` auto-triggers exit when `authenticated` after assembly completes.

---

## Colors & theming

### Entry-only background

Edit **`EntryAtmosphere.dart`** and **`TacticalGridPainter`** (inside `PrismPainters.dart`) for splash look.

App ice shell tokens live in **`HealthMetricColors`** (`iceBgDeep`, `iceBgMid`).

### App-wide tokens

**`EntryConstants.dart`** defines:

- `EntryColors` — ice/silver palette, department accents (finance, health, project, social)
- `EntryLandscapePalette` — reference swatches
- `EntryConstraints` — snack bar / login padding
- `EntryStyles` — auth status typography

Used across Finance, Canvas, Login, Home, etc. Changing a color here affects the whole app — not just entry.

---

## Geometry & painters

**`EntryGeometry`** — builds procedural data:

- `generateShardsOnly()` — lightweight list for entry (used by `PrismEntryPage`)
- Full constructor — cracks, particles, panes for heavier shatter scenes

**`PrismPainters.dart`** — large file containing:

- Models: `PrismShard`, `GlassCrackData`, `ScatteringParticleData`, …
- Painters: `PrismPainter`, `TacticalGridPainter`, `GlassShatterPainter`, `IceFlashPainter`, `ShockwavePainter`, …

Prefer **new painter classes in this file** or split by concern if the file grows further.

---

## Exit storyboard (future / Rive)

**`IceGateStoryboard.dart`** maps global progress `t ∈ [0,1]` to 10 phases (`seed` → `reveal`). Use `phaseAt(t)` and `localProgress(t, phase)` when syncing Flutter animations or a Rive state machine.

Current `PrismEntryPage` uses a simplified crack/shatter path; storyboard is the design reference for a fuller sequence.

---

## Optional / refactor widgets

These are extracted for clarity but **`PrismEntryPage` inlines much of the logic today**:

- `PrismMainContent` — background + logo column with crack opacity  
- `PremiumLogo` + `IcePetalBurst` — richer logo than current `_buildPremiumLogo`  
- `ShatterEffect` — bundles shatter painters  
- `ScanningStatusOverlay` + `AuthStatusPulse` — commented out in `PrismEntryPage`

When refactoring, prefer composing these instead of growing `PrismEntryPage` further.

---

## Assets

- Logo: `assets/images/icegate_entry_icon.png`

---

## Common tasks

| Task | Where |
|------|--------|
| Change splash background | `EntryAtmosphere.dart`, `TacticalGridPainter` vignette |
| Faster / slower assembly | `_assemblyController` duration in `PrismEntryPage` |
| More / fewer shards | `EntryGeometry.generateShardsOnly(80, …)` count |
| Exit destination | `_playElegantExit` → `context.go(...)` |
| Shared app accent color | `EntryColors` in `EntryConstants.dart` |
| New auth error string | `AuthErrorHelper` + l10n keys |

---

## Testing

- Cold start → entry route → tap logo → home or login  
- Hot **restart** after painter changes (hot reload may not repaint `CustomPaint` layers)  
- macOS window: pointer parallax on grid and atmosphere
