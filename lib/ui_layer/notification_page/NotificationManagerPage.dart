import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/initial_layer/Notification/NotificationInit.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';

class NotificationManagerPage extends StatefulWidget {
  const NotificationManagerPage({super.key});

  @override
  State<NotificationManagerPage> createState() =>
      _NotificationManagerPageState();
}

class _NotificationManagerPageState extends State<NotificationManagerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<LocalNotificationService>();
    final isEnabled = notificationService.notificationsEnabled.watch(context);

    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Container(color: colorScheme.surface.withOpacity(0.9)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "NOTIFICATION CENTER",
                              style: TextStyle(
                                color: Colors.blueAccent.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "HUNTER MODE ",
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                           
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close_rounded,
                                color: colorScheme.onSurface,
                                size: 30,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.onSurface
                                    .withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.05),
                        ),
                      ),
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.blueAccent.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.3),
                          ),
                        ),
                        labelColor: Colors.blueAccent,
                        unselectedLabelColor: colorScheme.onSurface.withOpacity(
                          0.4,
                        ),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: "QUESTS"),
                          Tab(text: "REMINDERS"),
                          Tab(text: "WISDOM"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSystemQuestsTab(context),
                          _buildRemindersTab(context, isEnabled),
                          _buildQuotesTab(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersTab(BuildContext context, bool isEnabled) {
    final notificationService = context.read<LocalNotificationService>();
    final customNotificationDao = context.watch<CustomNotificationDAO>();

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildGlassCard(
          child: SwitchListTile(
            value: isEnabled,
            onChanged: (val) =>
                notificationService.setNotificationsEnabled(val),
            title: Text(
              "Allow Notifications",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              isEnabled
                  ? "You will receive updates about your stats and tasks."
                  : "Notifications are paused.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled
                    ? Colors.greenAccent.withOpacity(0.2)
                    : Colors.redAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: isEnabled ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
            activeThumbColor: Colors.blueAccent,
          ),
        ),
        if (isEnabled) ...[
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Custom Reminders",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddNotificationDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text("Add New"),
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<CustomNotificationData>>(
            stream: customNotificationDao.watchAllNotifications(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      "No custom reminders set.",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildCustomNotificationTile(
                    context,
                    snapshot.data![index],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            "Quick Channels",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildChannelTile(
            "Daily Briefing",
            "Morning summary with quote of the day",
            Icons.wb_sunny_rounded,
            Colors.orangeAccent,
            onTest: () => notificationService.scheduleDailyNotification(),
          ),
          const SizedBox(height: 12),
          _buildChannelTile(
            "Quest Updates",
            "Task status and milestones",
            Icons.shield_rounded,
            Colors.purpleAccent,
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildSystemQuestsTab(BuildContext context) {
    final healthBlock = context.read<HealthBlock>();

    return Watch((context) {
      final steps = healthBlock.todaySteps.value;
      final stepGoal = healthBlock.dailyStepGoal.value;
      final water = healthBlock.todayWater.value;

      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseOpacity = (_pulseController.value * 0.2 + 0.2);
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.15),
                      Colors.cyan.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(pulseOpacity),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.1),
                      blurRadius: 20 * _pulseController.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "[ DAILY QUEST: IMMERSIVE STATS ]",
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.radar_rounded,
                      color: Colors.cyanAccent.withOpacity(0.8),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildQuestItem(
                  "Physical Training",
                  "Push-ups: 0 / 100",
                  0.0,
                  Colors.orangeAccent,
                  Icons.fitness_center_rounded,
                ),
                _buildQuestItem(
                  "Core Strength",
                  "Sit-ups: 0 / 100",
                  0.0,
                  Colors.greenAccent,
                  Icons.accessibility_new_rounded,
                ),
                _buildQuestItem(
                  "Leg Endurance",
                  "Squats: 0 / 100",
                  0.0,
                  Colors.blueAccent,
                  Icons.directions_run_rounded,
                ),
                _buildQuestItem(
                  "Movement Radius",
                  "$steps / $stepGoal m",
                  (steps / stepGoal).clamp(0.0, 1.0),
                  Colors.cyanAccent,
                  Icons.explore_rounded,
                ),
                _buildQuestItem(
                  "Molecular Support",
                  "$water / 2000 ml",
                  (water / 2000).clamp(0.0, 1.0),
                  Colors.lightBlueAccent,
                  Icons.water_drop_rounded,
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.cyanAccent, thickness: 0.5),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent.withOpacity(0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "WARNING: PERFORMANCE DEGRADATION DETECTED UPON FAILURE.",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "COMPLETED PROTOCOLS",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "SYSTEM INITIALIZED - NO RECORDS FOUND",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.15),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildQuestItem(
    String title,
    String progressText,
    double progress,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          progressText,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesTab(BuildContext context) {
    final quoteDao = context.watch<QuoteDAO>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Your Wisdom Board",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddQuoteDialog(context),
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text("New Quote"),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<QuoteData>>(
            stream: quoteDao
                .watchActiveQuotes(), // Or watchAll if we want to show disabled too
            builder: (context, snapshot) {
              final quotes = snapshot.data ?? [];
              if (quotes.isEmpty &&
                  snapshot.connectionState == ConnectionState.active) {
                return Center(
                  child: Text(
                    "Your wisdom board is empty.\nAdd quotes to inspire your day.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: quotes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final quote = quotes[index];
                  return _buildQuoteTile(context, quote);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child, Color? borderColor}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    borderColor ??
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTile(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTest,
  }) {
    return _buildGlassCard(
      borderColor: color.withOpacity(0.2),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        trailing: Switch(
          value: true,
          onChanged: (val) {},
          activeThumbColor: color,
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? color.withOpacity(0.4)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNotificationTile(
    BuildContext context,
    CustomNotificationData notification,
  ) {
    final dao = context.read<CustomNotificationDAO>();
    final service = context.read<LocalNotificationService>();
    final formattedTime = DateFormat(
      'MMM dd, HH:mm',
    ).format(notification.scheduledTime);

    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.content,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: notification.isEnabled,
                  onChanged: (val) async {
                    final updated = notification.copyWith(isEnabled: val);
                    await dao.updateNotification(updated);
                    await service.syncAllNotifications();
                  },
                  activeThumbColor: Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: () async {
                    await dao.deleteNotification(notification.notificationID);
                    await service.syncAllNotifications();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(minutes: 5));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    String repeatFrequency = 'once';
    List<int> repeatDays = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161B33),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "New Reminder",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: "Title",
                        labelStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: "Content",
                        labelStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF161B33),
                      initialValue: repeatFrequency,
                      items: ['once', 'daily', 'weekly'].map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(
                            f.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setDialogState(() => repeatFrequency = val!),
                      decoration: InputDecoration(
                        labelText: "Repeat",
                        labelStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    if (repeatFrequency == 'weekly') ...[
                      const SizedBox(height: 16),
                      Text(
                        "Select Days",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDayPicker(
                        repeatDays,
                        (days) => setDialogState(() => repeatDays = days),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Time: ${selectedTime.format(context)}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.access_time_rounded,
                        color: Colors.blueAccent,
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setDialogState(() => selectedTime = time);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) return;
                    final now = DateTime.now();
                    final scheduled = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    final dao = context.read<CustomNotificationDAO>();
                    final service = context.read<LocalNotificationService>();

                    dao
                        .insertNotification(
                          CustomNotificationsTableCompanion.insert(
                            title: titleController.text,
                            content: contentController.text,
                            scheduledTime: scheduled,
                            repeatFrequency: Value(repeatFrequency),
                            repeatDays: Value(
                              repeatDays.isEmpty ? null : repeatDays.join(','),
                            ),
                          ),
                        )
                        .then((id) {
                          // Trigger fresh sync
                          service.syncAllNotifications();
                          Navigator.pop(context);
                        });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDayPicker(
    List<int> selectedDays,
    Function(List<int>) onChanged,
  ) {
    final days = ["M", "T", "W", "T", "F", "S", "S"];
    return Wrap(
      spacing: 6,
      children: List.generate(7, (index) {
        final dayNum = index + 1; // 1=Mon, 7=Sun
        final isSelected = selectedDays.contains(dayNum);
        return InkWell(
          onTap: () {
            final newDays = List<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(dayNum);
            } else {
              newDays.add(dayNum);
            }
            onChanged(newDays);
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blueAccent
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showAddQuoteDialog(BuildContext context) {
    final contentController = TextEditingController();
    final authorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Inspirational Quote",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                maxLines: 3,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: _dialogInputDecoration("Quote Contents"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: _dialogInputDecoration("Author"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (contentController.text.isEmpty) return;
                final dao = context.read<QuoteDAO>();
                dao.insertQuote(
                  QuotesTableCompanion.insert(
                    content: contentController.text,
                    author: Value(
                      authorController.text.isEmpty
                          ? null
                          : authorController.text,
                    ),
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuoteTile(BuildContext context, QuoteData quote) {
    final dao = context.read<QuoteDAO>();
    return _buildGlassCard(
      borderColor: Colors.amberAccent.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: Colors.amberAccent.withOpacity(0.5),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    quote.content,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (quote.author != null)
                  Text(
                    "— ${quote.author}",
                    style: TextStyle(
                      color: Colors.amberAccent.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.2),
                    size: 18,
                  ),
                  onPressed: () => dao.deleteQuote(quote.quoteID),
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent),
      ),
    );
  }
}
