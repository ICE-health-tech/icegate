import 'package:flutter/material.dart'; // Standard Flutter Material
import 'package:ice_gate/initial_layer/DataLayer.dart';
import 'package:ice_gate/data_layer/Protocol/Theme/ThemeAdapter.dart';
import 'package:ice_gate/initial_layer/RoutingLayer.dart';
import 'package:ice_gate/initial_layer/ThemeLayer/ThemeLayer.dart';
import 'package:ice_gate/security_routing_layer/Routing/url_route/InternalRoute.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:media_kit/media_kit.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/LocaleBlock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Call runApp immediately to prevent iOS black screen/Xcode hang.
  // The actual initialization logic is handled inside DataLayer.
  runApp(
    const DataLayer(
      childWidget: ThemeLayer(childWidget: Adapter(childWidget: MyApp())),
    ),
  );
}

// 🚨 Assumption: ThemeStore now provides standard Material ThemeData.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the theme store instance
    final ThemeStore themeStore = context.watch<ThemeStore>();

    return Watch(
      // Outer Observer for MaterialApp properties
      (context) {
        // Assume ThemeStore now provides a standard ThemeData property
        // Replace currentNeumorphicTheme with your actual Material theme observable,
        // for example: themeStore.currentMaterialTheme
        final ThemeData currentTheme =
            themeStore.currentTheme.value ?? ThemeAdapter.lightTheme;

        // Đọc locale hiện tại từ LocaleBlock (reactive)
        Locale? appLocale;
        try {
          final localeBlock = context.read<LocaleBlock>();
          appLocale = localeBlock.currentLocale.watch(context);
        } catch (_) {
          // LocaleBlock chưa sẵn sàng, dùng locale mặc định
          appLocale = const Locale('vi');
        }

        // --- Use MaterialApp instead of NeumorphicApp ---
        return MaterialApp.router(
          // Apply the retrieved Material theme
          routerConfig: router,
          theme: currentTheme,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: appLocale, // Reactive locale từ LocaleBlock
          title: 'ICE Gate', // Standard MaterialApp title
        );
      },
    );
  }
}
