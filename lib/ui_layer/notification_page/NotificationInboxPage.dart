import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart'
    hide ThemeData;
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class NotificationInboxPage extends StatelessWidget {
  const NotificationInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final personBlock = context.watch<PersonBlock>();
    final personId = personBlock.currentPersonID.watch(context) ?? "";
    final questDao = context.watch<QuestDAO>();
    final notificationDao = context.watch<CustomNotificationDAO>();
    final focusSessionDao = context.watch<FocusSessionsDAO>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F172A),
                  colorScheme.surface,
                  const Color(0xFF1E293B),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: StreamBuilder<List<QuestData>>(
                    stream: questDao.watchAllQuests(personId),
                    builder: (context, questSnapshot) {
                      return StreamBuilder<List<CustomNotificationData>>(
                        stream: notificationDao.watchAllNotifications(personId),
                        builder: (context, notificationSnapshot) {
                          return StreamBuilder<List<FocusSessionData>>(
                            stream: focusSessionDao.watchAllSessions(),
                            builder: (context, focusSnapshot) {
                              final allQuests = questSnapshot.data ?? [];
                              final allNotifications =
                                  notificationSnapshot.data ?? [];
                              final allFocusSessions = focusSnapshot.data ?? [];

                              final completedQuests = allQuests
                                  .where((q) => q.isCompleted == true)
                                  .toList();

                              final completedFocusSessions = allFocusSessions
                                  .where((s) => s.status == 'completed')
                                  .toList();

                              // Combine into a single list of items
                              final List<dynamic> timelineItems = [
                                ...completedQuests,
                                ...allNotifications,
                                ...completedFocusSessions,
                              ];

                              // Sort by date (newest first)
                              timelineItems.sort((a, b) {
                                final dateA = _getDateTime(a);
                                final dateB = _getDateTime(b);
                                return dateB.compareTo(dateA);
                              });

                              if (timelineItems.isEmpty) {
                                return _buildEmptyState(context);
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: timelineItems.length,
                                itemBuilder: (context, index) {
                                  final item = timelineItems[index];
                                  if (item is QuestData) {
                                    return _buildQuestTile(context, item);
                                  } else if (item is CustomNotificationData) {
                                    return _buildNotificationTile(
                                      context,
                                      item,
                                    );
                                  } else if (item is FocusSessionData) {
                                    return _buildFocusSessionTile(
                                      context,
                                      item,
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime _getDateTime(dynamic item) {
    if (item is QuestData) return item.createdAt;
    if (item is CustomNotificationData) {
      return item.scheduledTime;
    }
    if (item is FocusSessionData) return item.startTime;
    return DateTime.now();
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.notification_inbox_title,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.notification_mission_history,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestTile(BuildContext context, QuestData quest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.blueAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.notification_mission_success,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(quest.createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  quest.title ?? AppLocalizations.of(context)!.project_note_untitled,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quest.description ?? AppLocalizations.of(context)!.notification_mission_success,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusSessionTile(
    BuildContext context,
    FocusSessionData session,
  ) {
    final durationMin = (session.durationSeconds / 60).floor();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_rounded,
              color: Colors.purpleAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.notification_focus_complete,
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(session.startTime),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${session.sessionType} Session: $durationMin min",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.notes!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    CustomNotificationData notification,
  ) {
    final timeStr = DateFormat('HH:mm').format(notification.scheduledTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForCategory(notification.category),
              color: Colors.white.withOpacity(0.7),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.notification_reminder,
                      style: TextStyle(
                        color: Colors.blueAccent.withOpacity(0.8),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (notification.content.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notification.content,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'health':
        return Icons.favorite_rounded;
      case 'finance':
        return Icons.account_balance_wallet_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'projects':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.notification_no_logs,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.notification_empty_desc,
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
