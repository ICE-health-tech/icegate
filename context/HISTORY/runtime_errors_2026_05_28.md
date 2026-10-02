# Runtime errors log — 2026-05-28

This file captures **all errors currently visible** from:

- the Flutter run console output (macOS desktop run)
- the UI screenshot showing an in-app error banner

If you need **Dart stack traces** for the in-app banner, follow the “How to capture missing stack traces” section.

---

## 1) In-app error banner (UI)

Observed on the login screen (red banner):

- Message: `Đã xảy ra lỗi không mong muốn: System Error`

This appears to be an app-level error handler (not a Flutter framework crash), but **no stack trace is shown in the terminal output we have**.

### Improvement applied (so this becomes debuggable)

The login UI previously hardcoded `System Error` for `err_unexpected`, which hides the real underlying exception.

Change applied in code: `AuthBlock._mapError` now returns `err_unexpected|<details>` for unknown failures, and UI helpers (`LoginPage`, `AuthErrorHelper`) render it via `l10n.err_unexpected(details)`.

Result: the red banner should show **the actual exception message**, so we can fix the true root cause next (network/config/auth/provider/etc.).

---

## 2) Console errors (macOS desktop target)

### A) Launch/foregrounding failure

Repeated during `flutter run` on macOS:

- `Failed to foreground app; open returned 1`

This is a macOS launch/activation issue (the app builds, then macOS fails to bring it to foreground).

### B) IMK (input method) mach port messaging error

Seen at `2026-05-28 10:39:14.945`:

- `error messaging the mach port for IMKCFRunLoopWakeUpReliable`

This is typically macOS InputMethodKit / keyboard input subsystem noise. It may be benign, but it’s an **error line** and is logged here.

---

## 3) Notes (non-error but relevant)

- `Application finished.` appears multiple times immediately after launch, which can indicate the app is closing early or being terminated right after start (may relate to the foregrounding problem or an unhandled exit path).

---

## 4) How to capture missing stack traces (recommended next run)

To log the real root cause for the in-app “System Error”, capture **verbose Flutter logs** and ensure Dart exceptions are printed.

### Option 1 — verbose Flutter run

Run:

```bash
flutter run -d macos -v
```

Then reproduce the error and copy the **first Dart exception stack trace** (look for `Exception`, `Error`, `Stack trace`, `#0` frames).

### Option 2 — enforce error logging in-app

If the banner is shown via a try/catch or a generic “System Error” mapping, ensure the catch path logs:

- original exception object
- stack trace
- any HTTP response/status/body (if network-related)

(We can wire this up once you point me to the code that triggers the banner.)

