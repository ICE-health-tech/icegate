// Retained for rootBundle.loadString if used in ThemeAdapter.parse
import 'package:flutter/material.dart'; // Import standard Material
import 'package:provider/provider.dart';

import 'package:ice_gate/data_layer/Protocol/Theme/ThemeAdapter.dart';

/// This widget asynchronously loads the initial Material theme data
/// and makes the necessary providers (ThemeStore, etc.) available to the child widget.
class ThemeLayer extends StatefulWidget {
  final Widget childWidget;

  const ThemeLayer({super.key, required this.childWidget});

  // Define the future function to load the theme data, now returning ThemeData
  // ⚠️ ASSUMPTION: ThemeAdapter.parse can return ThemeData
  Future<ThemeData> _loadTheme() async {
    try {
      // Try to load the saved theme configuration
      return await ThemeAdapter.parse("assets/CurrentTheme.json");
    } catch (e) {
      print(
        "Warning: Could not load CurrentTheme.json ($e). Falling back to SakuraZen.",
      );
      // Fallback to a default theme if the specific file is missing/corrupt
      return await ThemeAdapter.parse("assets/SakuraZen.json");
    }
  }

  @override
  State<ThemeLayer> createState() => _ThemeLayerState();
}

class _ThemeLayerState extends State<ThemeLayer> {
  // Variable to hold the Future, ensuring it's only created once
  late final Future<ThemeData> initialThemeData;
  // Change to standard ThemeData
  ThemeData? themeData;
  late ThemeStore themeStore;
  // This method is now redundant and can be removed or simplified
  Future<void> loadTheme() async {
    // Since theme store creation happens in build, this function is unnecessary
    // and its contents are commented out/removed.
  }

  @override
  void initState() {
    super.initState();
    // Initialize the Future by calling the method on the parent widget
    initialThemeData = widget._loadTheme();
    themeStore = ThemeStore();
    print(initialThemeData);
  }

  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder with the initialized Future
    // return FutureBuilder<ThemeData>( // Change NeumorphicThemeData to ThemeData
    //   future: _themeFuture,
    //   builder: (context, snapshot) {

    // // Handle Loading State (Use standard Material components)
    // // if (snapshot.connectionState == ConnectionState.waiting) {
    // //   // Wrap the indicator in a Material widget context for safe rendering
    // //   return const MaterialApp(
    // //     home: Scaffold(
    // //       body: Center(
    // //         child: CircularProgressIndicator(color: Colors.deepPurple),
    // //       ),
    // //     ),
    // //   );
    // // }

    // // // Handle Error State
    // // if (snapshot.hasError) {
    // //   // Wrap the error message in a Material context
    // //   return MaterialApp(
    // //     home: Scaffold(
    // //       body: Center(
    // //         child: Text(
    // //           'Error loading theme: ${snapshot.error}',
    // //           style: const TextStyle(color: Colors.red),
    // //         ),
    // //       ),
    // //     ),
    // //   );
    // // }

    // // Handle Success State
    // if (snapshot.hasData) {
    //   final ThemeData initialThemeData = snapshot.data!; // Change type

    //   // Create the MobX store instance, injecting the loaded theme data
    //   // ⚠️ You will need to ensure your ThemeStore constructor accepts ThemeData
    //   final ThemeStore themeStore = ThemeStore();

    return MultiProvider(
      providers: [
        // 1. Provide the initial loaded ThemeData (optional, but useful)
        Provider<Future<ThemeData>>.value(value: initialThemeData),

        // 2. Provide the MobX ThemeStore for reactive state management
        // (This store should now manage ThemeData)
        Provider<ThemeStore>.value(value: themeStore),

        // 3. Provide the static utility class
        Provider<ThemeAdapter>(create: (_) => ThemeAdapter()),
      ],
      // Pass control to the child (MyApp) via widget.childWidget
      child: widget.childWidget,
    );
  }

  // Fallback
  // return const MaterialApp(
  //     home: Scaffold(
  //         body: Center(child: Text("Initializing..."))
  //     )
  // );
  // },
  // );
  // }
}
