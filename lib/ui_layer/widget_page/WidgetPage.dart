import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/WidgetCard.dart';
// import 'package:ice_shield/ui_layer/ReusableWidget/WidgetCard.dart'
// hide ExternalWidget, ExternalWidgetsDAO;
import 'package:ice_shield/ui_layer/widget_page/AddPluginForm.dart';
import 'package:ice_shield/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';

class WidgetPage extends StatefulWidget {
  const WidgetPage({super.key});

  static Widget icon() {
    return Builder(
      builder: (context) {
        return IconButton(
          icon: Icon(
            Icons.extension_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            context.go('/widgets');
          },
        );
      },
    );
  }

  @override
  State<WidgetPage> createState() => _WidgetPage();
}

class _WidgetPage extends State<WidgetPage> {
  // --- Helper Methods (Unchanged) ---

  // Future<void> _navigateExternalUrl(String url) async {
  //   final uri = Uri.tryParse(url);
  //   if (uri != null && await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //   } else {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Could not launch $url')),
  //       );
  //     }
  //   }
  // }

  void _openPopupForm(BuildContext context, ExternalWidgetsDAO dao) async {
    final bool? didSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: AddPluginForm(data: FormData(title: "Add widget")),
        );
      },
    );

    if (didSave == true && mounted) {
      // Use theme text style for SnackBar text
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New widget added!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Fetching the ColorScheme once for cleaner code
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dao = context.read<ExternalWidgetsDAO>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, size: 30),
            onPressed: () {
              WidgetNavigatorAction.smartPop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, size: 30),
            onPressed: () => context.go('/canvas'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 30),
            onPressed: () => context.go('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ExternalWidgetData>>(
        stream: dao.watchAllWidgets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 4. Use accent color for loading indicator
            return Center(
              child: CircularProgressIndicator(color: colorScheme.secondary),
            );
          }

          if (snapshot.hasError) {
            // 5. Use error color for error messages
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No widgets found. Tap + to add one!',
                // 6. Use a subtle theme color (e.g., onSurface.withOpacity)
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            );
          }

          // --- Data Loaded State ---
          final externalWidgetList = snapshot.data!;

          return GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(8),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,

            children: externalWidgetList.map((widgetData) {
              try {
                final String fullUrl =
                    "${widgetData.protocol}://${widgetData.host}${widgetData.url}";
                // Ensure WidgetCard uses theme data internally
                return WidgetCard(
                  context: context,
                  dao: dao,
                  widgetData: widgetData,
                  fullUrl: fullUrl,
                );
              } catch (e) {
                print('Error building WidgetCard: $e');
                // 7. Use surface color for placeholder
                return Container(color: colorScheme.surface);
              }
            }).toList(),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPopupForm(context, dao),
        // 8. FAB uses secondary color by convention
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
