import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/initial_layer/Notification/NotificationInit.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';

class CustomNotificationManagerPage extends StatelessWidget {
  const CustomNotificationManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dao = context.watch<CustomNotificationDAO>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Personal Reminders',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            onPressed: () => _showNotificationDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<CustomNotificationData>>(
        stream: dao.watchAllNotifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 80,
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reminders set',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showNotificationDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Reminder'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    CustomNotificationData notification,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final dao = context.read<CustomNotificationDAO>();
    final service = context.read<LocalNotificationService>();

    final timeStr = DateFormat('hh:mm a').format(notification.scheduledTime);
    final isEnabled = notification.isEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnabled
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.outline.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isEnabled ? colorScheme.primary : colorScheme.outline)
                .withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getCategoryIcon(notification.category),
            color: isEnabled ? colorScheme.primary : colorScheme.outline,
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isEnabled ? colorScheme.onSurface : colorScheme.outline,
            decoration: isEnabled ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: colorScheme.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                if (notification.repeatFrequency != 'once')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (notification.repeatFrequency ?? 'ONCE').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch.adaptive(
              value: isEnabled,
              onChanged: (val) {
                dao
                    .patchNotification(
                      notification.id,
                      CustomNotificationsTableCompanion(isEnabled: Value(val)),
                    )
                    .then((_) => service.syncAllNotifications());
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showNotificationDialog(context, existing: notification);
                } else if (value == 'delete') {
                  _confirmDelete(context, notification);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    CustomNotificationData notification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: Text(
          'Are you sure you want to delete "${notification.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final dao = context.read<CustomNotificationDAO>();
              final service = context.read<LocalNotificationService>();
              dao.deleteNotification(notification.id).then((_) {
                service.syncAllNotifications();
                Navigator.pop(context);
              });
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(
    BuildContext context, {
    CustomNotificationData? existing,
  }) {
    final titleController = TextEditingController(text: existing?.title);
    final contentController = TextEditingController(text: existing?.content);
    DateTime selectedDate =
        existing?.scheduledTime ??
        DateTime.now().add(const Duration(minutes: 5));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    String repeatFrequency = existing?.repeatFrequency ?? 'once';
    List<int> repeatDays =
        existing?.repeatDays
            ?.split(',')
            .where((s) => s.isNotEmpty)
            .map((s) => int.parse(s))
            .toList() ??
        [];
    String selectedCategory = existing?.category ?? 'General';
    String selectedPriority = existing?.priority ?? 'Normal';

    final categories = {
      'General': Icons.notifications_none_rounded,
      'Health': Icons.favorite_rounded,
      'Finance': Icons.account_balance_wallet_rounded,
      'Social': Icons.people_rounded,
      'Projects': Icons.rocket_launch_rounded,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surfaceTint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: Text(
                existing == null ? "New Reminder" : "Edit Reminder",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Title",
                        prefixIcon: const Icon(Icons.title_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: "Short Note",
                        prefixIcon: const Icon(Icons.subject_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Picker
                    const Text(
                      "Category",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.entries.map((e) {
                        final isSelected = selectedCategory == e.key;
                        return InkWell(
                          onTap: () =>
                              setDialogState(() => selectedCategory = e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withOpacity(0.12)
                                  : colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  e.value,
                                  size: 16,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  e.key,
                                  style: TextStyle(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Time and Repeat
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: repeatFrequency,
                            items: ['once', 'daily', 'weekly'].map((f) {
                              return DropdownMenuItem(
                                value: f,
                                child: Text(
                                  f.toUpperCase(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setDialogState(() => repeatFrequency = val!),
                            decoration: InputDecoration(
                              labelText: "Repeat",
                              prefixIcon: const Icon(Icons.repeat_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setDialogState(() => selectedTime = time);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: "Time",
                                prefixIcon: const Icon(
                                  Icons.access_time_rounded,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(selectedTime.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (repeatFrequency == 'weekly') ...[
                      const SizedBox(height: 16),
                      _buildDayPicker(
                        colorScheme,
                        repeatDays,
                        (days) => setDialogState(() => repeatDays = days),
                      ),
                    ],
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

                    if (existing == null) {
                      dao
                          .insertNotification(
                            CustomNotificationsTableCompanion.insert(
                              id: IDGen.generateUuid(),
                              title: titleController.text,
                              content: contentController.text,
                              scheduledTime: scheduled,
                              repeatFrequency: Value(repeatFrequency),
                              repeatDays: Value(
                                repeatDays.isEmpty
                                    ? null
                                    : repeatDays.join(','),
                              ),
                              category: Value(selectedCategory),
                              priority: Value(selectedPriority),
                              isEnabled: const Value(true),
                              createdAt: Value(DateTime.now()),
                            ),
                          )
                          .then((_) {
                            service.syncAllNotifications();
                            Navigator.pop(context);
                          });
                    } else {
                      dao
                          .patchNotification(
                            existing.id,
                            CustomNotificationsTableCompanion(
                              title: Value(titleController.text),
                              content: Value(contentController.text),
                              scheduledTime: Value(scheduled),
                              repeatFrequency: Value(repeatFrequency),
                              repeatDays: Value(
                                repeatDays.isEmpty
                                    ? null
                                    : repeatDays.join(','),
                              ),
                              category: Value(selectedCategory),
                              priority: Value(selectedPriority),
                            ),
                          )
                          .then((_) {
                            service.syncAllNotifications();
                            Navigator.pop(context);
                          });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(existing == null ? "Save" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDayPicker(
    ColorScheme colorScheme,
    List<int> selectedDays,
    Function(List<int>) onChanged,
  ) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Health':
        return Icons.favorite_rounded;
      case 'Finance':
        return Icons.account_balance_wallet_rounded;
      case 'Social':
        return Icons.people_rounded;
      case 'Projects':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
