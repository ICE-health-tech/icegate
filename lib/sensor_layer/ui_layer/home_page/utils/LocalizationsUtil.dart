import 'package:flutter/widgets.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class LocalizationsUtil {
  static AppLocalizations? of(BuildContext context) {
    return AppLocalizations.of(context);
  }

  static String l(BuildContext context, String Function(AppLocalizations) getter, {String fallback = ''}) {
    final l10n = of(context);
    if (l10n == null) return fallback;
    return getter(l10n);
  }
}
