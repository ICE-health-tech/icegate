import 'package:flutter/material.dart';
// NOTE: Please ensure these imports are correct for your project structure
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart'
    hide ThemeData;
// import 'package:ice_shield/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Home/ExternalWidgetBlock.dart';
import 'package:ice_shield/data_layer/Protocol/Theme/ThemeAdapter.dart';
// import 'package:ice_shield/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:provider/provider.dart';

import '../orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';

class Adapter extends StatefulWidget {
  final Widget childWidget;

  const Adapter({super.key, required this.childWidget});

  @override
  State<Adapter> createState() => _adapterState();
}

class _adapterState extends State<Adapter> {
  ThemeData? themeData;
  late ThemeStore themeStore;

  InternalWidgetBlock internalWidgetBlock = InternalWidgetBlock();
  ExternalWidgetBlock externalWidgetBlock = ExternalWidgetBlock();
  late AuthBlock authBlock;
  late AppDatabase appDatabase;

  void _initAsyncDatabaseLink() async {
    final dao = appDatabase.internalWidgetsDAO;
    final externalDao = appDatabase.externalWidgetsDAO;
    final themeDao = appDatabase.themeDAO;

    // Load the saved theme from SharedPreferences (local-only, never synced).
    final savedTheme = await themeDao.getCurrentTheme();
    themeStore.loadTheme(savedTheme.themePath);

    final existingWidget = await dao.getInternalWidgetByName("WidgetPage");
    if (existingWidget == null) {
      await dao.insertInternalWidget(
        name: "WidgetPage",
        imageUrl: "assets/internalwidget/defaul.png",
        url: "/canvas",
        alias: "WidgetPage",
      );

      await dao.insertInternalWidget(
        name: "Health Department",
        imageUrl: "assets/internalwidget/defaul.png",
        url: "/health",
        alias: "HealthPage",
      );
    }

    internalWidgetBlock.refreshBlock(dao);
    externalWidgetBlock.refreshBlock(externalDao);
  }

  @override
  void initState() {
    super.initState();
    appDatabase = context.read<AppDatabase>();
    themeStore = context.read<ThemeStore>();
    authBlock = context.read<AuthBlock>();
    _initAsyncDatabaseLink();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<InternalWidgetBlock>.value(value: internalWidgetBlock),
        Provider<ExternalWidgetBlock>.value(value: externalWidgetBlock),

        // 5. Provide the AuthBlock
        Provider<AuthBlock>.value(value: authBlock),
      ],
      child: widget.childWidget,
    );
  }
}
