import 'package:flutter/widgets.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

extension LocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
