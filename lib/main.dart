import 'package:flutter/material.dart'; // Standard Flutter Material
import 'package:ice_shield/initial_layer/DataLayer.dart';
import 'package:ice_shield/data_layer/Protocol/Theme/ThemeAdapter.dart';
import 'package:ice_shield/initial_layer/RoutingLayer.dart';
import 'package:ice_shield/initial_layer/ThemeLayer/ThemeLayer.dart';
import 'package:ice_shield/security_routing_layer/Routing/url_route/InternalRoute.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

        // --- Use MaterialApp instead of NeumorphicApp ---
        return MaterialApp.router(
          // Apply the retrieved Material theme
          routerConfig: router,
          theme: currentTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: FlutterQuillLocalizations.supportedLocales,

          // You might have a separate darkTheme and themeMode in the store
          // darkTheme: themeStore.darkMaterialTheme,
          // themeMode: themeStore.currentThemeMode,
          title: 'ICE Gate', // Standard MaterialApp title
          // home: HomePage(title: 'Home Page'),
        );
      },
    );
  }
}
