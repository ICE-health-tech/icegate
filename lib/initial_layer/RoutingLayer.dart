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

    final existingWidget = await dao.getInternalWidgetByName("WidgetPage");
    final existingTheme = await themeDao.getCurrentTheme();

    if (existingTheme == null) {
      await themeDao.insertTheme(
        themeName: "CurrentTheme",
        themePath: "assets/SeedBlue.json",
      );
    }

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
      print("DUYLONG routing: $dao");
    } else {
      print("Default internal widgets already exist. Skipping insertion.");
    }

    internalWidgetBlock.refreshBlock(dao);
    externalWidgetBlock.refreshBlock(externalDao);
  }

  @override
  void initState() {
    super.initState();
    appDatabase = context.read<AppDatabase>();
    _initAsyncDatabaseLink();
    themeStore = context.read<ThemeStore>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var currentThemeData = await appDatabase.themeDAO.getCurrentTheme();
      themeStore.loadTheme(currentThemeData?.themePath ?? "");
    });

    // AuthBlock is already initialized and checking session in DataLayer.
    // We just need to ensure it's available in this scope if needed,
    // but better to read it in build() or where used.
    authBlock = context.read<AuthBlock>();
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
