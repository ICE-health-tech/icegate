# Fix: TalkSSH Localization Import and Missing Keys

## Issue Description
Running `flutter analyze` reported multiple errors indicating `AppLocalizations` was undefined or the URI could not be found within the `TalkSSH` plugin widget files:
- `TalkSSHPage.dart`
- `SSHSearchBar.dart`
- `SSHAIGenerator.dart`
- `SSHHeader.dart`
- `SSHCommandInput.dart`

The localization configuration (`l10n.yaml`) defines `output-dir: lib/l10n`, which means localization files should be imported via `package:ice_gate/l10n/app_localizations.dart` rather than the default `package:flutter_gen/gen_l10n/app_localizations.dart`. Additionally, several SSH-specific string keys were missing in `app_en.arb` and `app_vi.arb`.

## Changes Made
1. **Updated Imports:** 
   - Replaced `import 'package:flutter_gen/gen_l10n/app_localizations.dart';` with `import 'package:ice_gate/l10n/app_localizations.dart';` in all the affected `TalkSSH` sub-widget files.
   - Added the correct import in `TalkSSHPage.dart`.

2. **Added Missing ARB Keys:**
   Added the following keys and their translations to `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`:
   - `ssh_new_session`
   - `ssh_host_label`
   - `ssh_port_label`
   - `ssh_user_label`
   - `ssh_pass_label`
   - `ssh_connect`
   - `ssh_ask_ai`
   - `ssh_ask_ai_desc`
   - `ssh_generate`
   - `ssh_type_command`
   - `ssh_disconnect`
   - `ssh_search_hint`

3. **Regenerated Localizations:** 
   - Ran `flutter gen-l10n` to successfully build the `.dart` localization class files. `flutter analyze` no longer produces compile errors.
