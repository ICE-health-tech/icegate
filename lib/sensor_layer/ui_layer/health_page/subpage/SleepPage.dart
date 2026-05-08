import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:drift/drift.dart' as drift;

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  final _selectedDate = signal<DateTime>(DateTime.now());
  TimeOfDay bedTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int quality = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSync();
    });
  }

  void _checkAndSync() {
    final healthBlock = context.read<HealthBlock>();
    healthBlock.syncSleepSessions(_selectedDate.value);
  }

  void _previousDay() {
    _selectedDate.value = _selectedDate.value.subtract(const Duration(days: 1));
    _checkAndSync();
  }

  void _nextDay() {
    final nextDay = _selectedDate.value.add(const Duration(days: 1));
    if (nextDay.isBefore(DateTime.now().add(const Duration(days: 1)))) {
      _selectedDate.value = nextDay;
      _checkAndSync();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate.value) {
      _selectedDate.value = picked;
      _checkAndSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dao = context.watch<HealthLogsDAO>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDateValue = _selectedDate.watch(context);
    final colorScheme = Theme.of(context).colorScheme;
    final personId = Supabase.instance.client.auth.currentUser?.id ?? "";

    return StreamBuilder<List<SleepLogData>>(
      stream: dao.watchSleepLogs(personId),
      builder: (context, snapshot) {
        final allLogs = snapshot.data ?? [];
        final logs = allLogs.where((l) => 
          l.startTime.year == selectedDateValue.year && 
          l.startTime.month == selectedDateValue.month && 
          l.startTime.day == selectedDateValue.day
        ).toList();

        int totalMinutes = 0;
        for (var log in logs) {
          if (log.endTime != null) {
            totalMinutes += log.endTime!.difference(log.startTime).inMinutes;
          }
        }

        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
          body: Stack(
            children: [
              // Background Gradient
              if (isDark)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.5,
                        colors: [
                          const Color(0xFF673AB7).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              CustomScrollView(
                slivers: [
                  // Custom Header
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        'Giấc ngủ',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => _showAddRecordSheet(context, dao),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Date Selector
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildNavButton(Icons.chevron_left, _previousDay, isDark),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('EEEE, d MMM').format(selectedDateValue),
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (DateFormat('yyyy-MM-dd').format(selectedDateValue) ==
                                        DateFormat('yyyy-MM-dd').format(DateTime.now()))
                                      Text(
                                        'Hôm nay',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              _buildNavButton(Icons.chevron_right, _nextDay, isDark),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        // Main Value Circle
                        _buildMainDisplay(hours, minutes, isDark),

                        const SizedBox(height: 40),

                        // Sleep Chart
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Text(
                                "BIỂU ĐỒ GIẤC NGỦ",
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSleepChart(isDark, logs),
                        
                        const SizedBox(height: 32),

                        // Summary Info
                        _buildSummaryCards(isDark, logs),
                        
                        const SizedBox(height: 32),

                        // Records List
                        if (logs.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Text(
                                  "DANH SÁCH BẢN GHI",
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildRecordsList(isDark, logs),
                        ],

                        const SizedBox(height: 32),
                        _buildEducationalCard(isDark),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed, bool isDark) {
    return IconButton(
      icon: Icon(
        icon,
        color: isDark ? Colors.white38 : Colors.grey.shade400,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildMainDisplay(int hours, int minutes, bool isDark) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Ring
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: (hours + minutes/60) / 8.0, // 8 hours goal
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF673AB7)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "$hours",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "h",
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$minutes",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "m",
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                'THỜI GIAN NGỦ',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepChart(bool isDark, List<SleepLogData> logs) {
    // Basic representation of sleep sessions throughout the day
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(24, (index) {
          bool hasSleep = false;
          for (var log in logs) {
            if (log.startTime.hour <= index && (log.endTime?.hour ?? 23) >= index) {
              hasSleep = true;
              break;
            }
          }
          return Container(
            width: 8,
            height: hasSleep ? 60.0 : 4.0,
            decoration: BoxDecoration(
              color: hasSleep 
                ? const Color(0xFF673AB7).withValues(alpha: 0.8) 
                : (isDark ? Colors.white10 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark, List<SleepLogData> logs) {
    if (logs.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Chất lượng',
              'Tốt',
              Icons.star_rounded,
              Colors.amber,
              isDark,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Mục tiêu',
              '8h',
              Icons.flag_rounded,
              Colors.green,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(bool isDark, List<SleepLogData> logs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: logs.map((log) {
          final duration = log.endTime != null 
              ? log.endTime!.difference(log.startTime)
              : const Duration();
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF673AB7).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    log.source != null ? Icons.devices_rounded : Icons.bedtime_rounded, 
                    size: 18,
                    color: const Color(0xFF673AB7),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${DateFormat('HH:mm').format(log.startTime)} - ${log.endTime != null ? DateFormat('HH:mm').format(log.endTime!) : '--:--'}",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (log.source != null)
                        Text(
                          log.source!,
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  "${duration.inHours}h ${duration.inMinutes % 60}m",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEducationalCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF673AB7).withValues(alpha: 0.05) : const Color(0xFF673AB7).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF673AB7).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF673AB7), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Tại sao giấc ngủ quan trọng?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Giấc ngủ chất lượng giúp cơ thể phục hồi, cải thiện trí nhớ và tăng cường hệ miễn dịch. Hãy cố gắng duy trì thói quen ngủ đủ 7-8 tiếng mỗi ngày.',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRecordSheet(BuildContext context, HealthLogsDAO dao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text("Thêm bản ghi giấc ngủ", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker(
                        context,
                        "Giờ đi ngủ",
                        bedTime,
                        Icons.bedtime_rounded,
                        (t) => setModalState(() => bedTime = t),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker(
                        context,
                        "Giờ thức dậy",
                        wakeTime,
                        Icons.wb_sunny_rounded,
                        (t) => setModalState(() => wakeTime = t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveSleep(context, dao);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Lưu bản ghi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    String label,
    TimeOfDay time,
    IconData icon,
    Function(TimeOfDay) onPicked,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF673AB7), size: 24),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  void _saveSleep(BuildContext context, HealthLogsDAO dao) async {
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day, bedTime.hour, bedTime.minute);
    DateTime end = DateTime(now.year, now.month, now.day, wakeTime.hour, wakeTime.minute);
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));

    await dao.insertSleepLog(
      SleepLogsTableCompanion.insert(
        id: IDGen.generateUuid(),
        personID: drift.Value(Supabase.instance.client.auth.currentUser?.id ?? ""),
        startTime: start,
        endTime: drift.Value(end),
        quality: drift.Value(quality),
      ),
    );
    _checkAndSync();
  }
}
