import 'package:flutter/material.dart';
// NOTE: Please ensure these imports are correct for your project structure
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart'
    hide ThemeData;
// import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/ExternalWidgetBlock.dart';
import 'package:ice_gate/data_layer/Protocol/Theme/ThemeAdapter.dart';
// import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:provider/provider.dart';

import '../orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FeedbackBlock.dart';
import 'package:provider/provider.dart';

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
  late PersonBlock personBlock;
  late AppDatabase appDatabase;
  FeedbackBlock feedbackBlock = FeedbackBlock();

  void _initAsyncDatabaseLink() async {
    final dao = appDatabase.internalWidgetsDAO;
    final externalDao = appDatabase.externalWidgetsDAO;
    final themeDao = appDatabase.themeDAO;

    // Load the saved theme from SharedPreferences (local-only, never synced).
    final savedTheme = await themeDao.getCurrentTheme();
    themeStore.loadTheme(savedTheme.themePath);

    final personId = personBlock.information.value.profiles.id ?? "";

    final existingWidgets = await dao.getInternaListWidgetByListName([
      "WidgetPage",
      "Health Department",
      "Block Reminder",
      "ICE GATE SSH"
    ]);

    final existingNames = existingWidgets.map((e) => e.name).toSet();

    if (!existingNames.contains("WidgetPage")) {
      await dao.insertInternalWidget(
        name: "WidgetPage",
        personID: personId,
        imageUrl: "assets/internalwidget/defaul.png",
        url: "/canvas",
        alias: "WidgetPage",
        scope: 'home',
      );
    }

    if (!existingNames.contains("Health Department")) {
      await dao.insertInternalWidget(
        name: "Health Department",
        personID: personId,
        imageUrl: "assets/internalwidget/defaul.png",
        url: "/health",
        alias: "HealthPage",
        scope: 'home',
      );
    }

    if (!existingNames.contains("Block Reminder")) {
      await dao.insertInternalWidget(
        name: "Block Reminder",
        personID: personId,
        imageUrl: "assets/internalwidget/defaul.png",
        url: "/health/block-reminder",
        alias: "BlockReminder",
        scope: 'home',
      );
    }

    if (!existingNames.contains("ICE GATE SSH")) {
      await dao.insertInternalWidget(
        name: "ICE GATE SSH",
        personID: personId,
        imageUrl: "assets/internalwidget/defaul.png",
        url: "/widgets/ssh",
        alias: "SSHTerminal",
        scope: 'home',
      );
    }

    internalWidgetBlock.refreshBlock(dao, personId, 'home');
    externalWidgetBlock.refreshBlock(externalDao, personId);
    feedbackBlock.init(appDatabase.feedbackDAO, personId);
  }

  @override
  void initState() {
    super.initState();
    appDatabase = context.read<AppDatabase>();
    themeStore = context.read<ThemeStore>();
    authBlock = context.read<AuthBlock>();
    personBlock = context.read<PersonBlock>();
    _initAsyncDatabaseLink();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<InternalWidgetBlock>.value(value: internalWidgetBlock),
        Provider<ExternalWidgetBlock>.value(value: externalWidgetBlock),

        Provider<AuthBlock>.value(value: authBlock),
        Provider<PersonBlock>.value(value: personBlock),
        Provider<FeedbackBlock>.value(value: feedbackBlock),
      ],
      child: widget.childWidget,
    );
  }
}
