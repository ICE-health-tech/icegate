import 'package:flutter/material.dart';
import 'package:ice_gate/ui_layer/health_page/HealthPage.dart';
import 'package:ice_gate/ui_layer/projects_page/FocusPage.dart';
import 'package:ice_gate/ui_layer/user_page/HunterInformationPage.dart';
import 'package:ice_gate/ui_layer/projects_page/ProjectsPage.dart';
import 'package:ice_gate/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_gate/ui_layer/social_page/SocialPage.dart';
import 'package:ice_gate/ui_layer/user_page/AnalysisDashboardPage.dart';
import 'package:ice_gate/ui_layer/projects_page/TextEditorPage.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SettingWidget.dart';
import 'package:ice_gate/ui_layer/projects_page/ProjectNotesPage.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/IOTTracker/GPSTrackingPage.dart';

typedef WidgetFactory = Widget Function({String? identifier});

class WidgetNameMapping {
  static final Map<String, WidgetFactory> _widgetMap = {
    "UserInformationPage": ({identifier}) => const UserInformationPage(),
    "HealthPage": ({identifier}) => const HealthPage(),
    "FocusPage": ({identifier}) => const FocusPage(),
    "ProjectsPage": ({identifier}) => const ProjectsPage(),
    "FinancePage": ({identifier}) => const FinancePage(),
    "SocialPage": ({identifier}) => const SocialPage(),
    "ProfilePage": ({identifier}) => const AnalysisDashboardPage(),
    "NotesPage": ({identifier}) => const TextEditorPage(),
    "SettingsPage": ({identifier}) => const SettingsWidget(),
    "ProjectNotes": ({identifier}) => const ProjectNotesPage(),
    "GPSPage": ({identifier}) => const GPSTrackingPage(),
  };

  Widget getWidgetByName(String name) {
    final widgetFactory = _widgetMap[name];
    if (widgetFactory != null) {
      return widgetFactory(identifier: name);
    } else {
      return Error404Widget(routeName: name);
    }
  }

  List<Widget> getWidgetByListName(List<String> listName) {
    List<Widget> widgetList = [];
    for (var name in listName) {
      final factory = _widgetMap[name];
      if (factory != null) {
        widgetList.add(factory(identifier: name));
      } else {
        widgetList.add(Error404Widget(routeName: name));
      }
    }
    return widgetList;
  }
}

class Error404Widget extends StatelessWidget {
  final String routeName;
  const Error404Widget({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error 404'),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Widget Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'The widget route "$routeName" could not be resolved.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
