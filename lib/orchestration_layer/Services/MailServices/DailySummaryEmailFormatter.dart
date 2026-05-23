import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';

/// Pre-formatted strings for n8n email nodes (avoids empty fields when values are 0).
class DailySummaryEmailFormatter {
  static String _label(String locale, String en, String vi) =>
      locale.startsWith('vi') ? vi : en;

  static String _money(FinanceBlock finance, double amount) =>
      finance.formatCurrency(amount);

  static String _num(num value, {int decimals = 0, String suffix = ''}) {
    if (value is double && decimals > 0) {
      return '${value.toStringAsFixed(decimals)}$suffix';
    }
    return '${value.round()}$suffix';
  }

  static String _ratio(num value, num goal, {String unit = ''}) {
    if (goal > 0) return '${_num(value)} / ${_num(goal)}$unit';
    return '${_num(value)}$unit';
  }

  static String _optionalNum(num value, {String suffix = '', String empty = '—'}) {
    if (value <= 0) return empty;
    return '${_num(value)}$suffix';
  }

  static String _optionalDouble(num value, {int decimals = 1, String suffix = ''}) {
    if (value <= 0) return '—';
    return '${value.toStringAsFixed(decimals)}$suffix';
  }

  static String formatTransactionsBlock({
    required String locale,
    required FinanceBlock finance,
    required List<Map<String, dynamic>> transactions,
  }) {
    if (transactions.isEmpty) {
      return _label(
        locale,
        'No transactions logged today.',
        'Chưa có giao dịch hôm nay.',
      );
    }
    final lines = <String>[];
    for (final t in transactions) {
      final type = '${t['type']}';
      final label = (t['label'] ?? t['category'] ?? 'other').toString();
      final amount = (t['amount'] as num?)?.toDouble() ?? 0;
      final desc = (t['description'] as String?)?.trim();
      final amt = _money(finance, amount);
      lines.add(
        desc != null && desc.isNotEmpty
            ? '• $type · $label · $amt · $desc'
            : '• $type · $label · $amt',
      );
    }
    return lines.join(_nl);
  }

  static String moodLabel(int score, String locale) {
    switch (score) {
      case 1:
        return _label(locale, 'Awful', 'Tồi tệ');
      case 2:
        return _label(locale, 'Bad', 'Tệ');
      case 3:
        return _label(locale, 'Meh', 'Bình thường');
      case 4:
        return _label(locale, 'Good', 'Tốt');
      case 5:
        return _label(locale, 'Rad', 'Tuyệt');
      default:
        return _label(locale, 'Unknown', 'Không rõ');
    }
  }

  static String formatNameList({
    required String locale,
    required List<dynamic> names,
    required String emptyMessage,
  }) {
    if (names.isEmpty) return emptyMessage;
    return names.map((e) => e.toString()).join(', ');
  }

  /// One item per line (for email body readability).
  static String formatNameListMultiline({
    required List<dynamic> names,
    required String emptyMessage,
  }) {
    if (names.isEmpty) return emptyMessage;
    return names.map((e) => '• ${e.toString()}').join('\n');
  }

  static const String _nl = '\r\n';

  static Map<String, String> buildFormattedFields({
    required String locale,
    required FinanceBlock finance,
    required Map<String, dynamic> totals,
    required Map<String, dynamic> financeSection,
    required Map<String, dynamic> healthSection,
    required Map<String, dynamic> moodSection,
    required Map<String, dynamic> projectsSection,
    required String periodLabel,
    required int transactionCount,
    required List<Map<String, dynamic>> todayTransactions,
    required int subscriptionCount,
  }) {
    final income = (totals['income'] as num?)?.toDouble() ?? 0;
    final expense = (totals['expense'] as num?)?.toDouble() ?? 0;
    final net = (totals['net'] as num?)?.toDouble() ?? 0;

    final steps = healthSection['steps'] as num? ?? 0;
    final stepGoal = healthSection['step_goal'] as num? ?? 0;
    final sleep = healthSection['sleep_hours'] as num? ?? 0;
    final sleepGoal = healthSection['sleep_goal'] as num? ?? 0;
    final water = healthSection['water_ml'] as num? ?? 0;
    final waterGoal = healthSection['water_goal'] as num? ?? 0;
    final hr = healthSection['heart_rate'] as num? ?? 0;
    final spo2 = healthSection['oxygen_saturation'] as num? ?? 0;
    final kcalBurned = healthSection['calories_burned'] as num? ?? 0;
    final kcalConsumed = healthSection['calories_consumed'] as num? ?? 0;
    final kcalGoal = healthSection['calorie_goal'] as num? ?? 0;
    final exercise = healthSection['exercise_minutes'] as num? ?? 0;
    final exerciseGoal = healthSection['exercise_goal'] as num? ?? 0;
    final focus = healthSection['focus_minutes'] as num? ?? 0;
    final focusGoal = healthSection['focus_goal'] as num? ?? 0;
    final weight = healthSection['weight_kg'] as num? ?? 0;

    final netWorth = (financeSection['net_worth'] as num?)?.toDouble() ?? 0;
    final monthlyIncome =
        (financeSection['monthly_income'] as num?)?.toDouble() ?? 0;
    final monthlySpending =
        (financeSection['monthly_spending'] as num?)?.toDouble() ?? 0;
    final monthlyNet = (financeSection['monthly_net'] as num?)?.toDouble() ?? 0;
    final totalSavings =
        (financeSection['total_savings'] as num?)?.toDouble() ?? 0;
    final dailyDelta = (financeSection['daily_delta'] as num?)?.toDouble() ?? 0;
    final remainingBudget =
        (financeSection['remaining_budget'] as num?)?.toDouble() ?? 0;
    final budgetUsage =
        (financeSection['budget_usage_percent'] as num?)?.toDouble() ?? 0;
    final savingsRate =
        (financeSection['savings_rate_percent'] as num?)?.toDouble() ?? 0;
    final drawdown =
        (financeSection['drawdown_percent'] as num?)?.toDouble() ?? 0;

    final txBlock = formatTransactionsBlock(
      locale: locale,
      finance: finance,
      transactions: todayTransactions,
    );

    final hasMoodToday = moodSection['has_log_today'] == true;
    final moodScore = moodSection['mood_score'] as int?;
    final moodActivities =
        (moodSection['activities'] as List?)?.cast<String>() ?? const [];
    final moodNote = moodSection['note'] as String?;

    final projectsTotal = projectsSection['projects_total'] as int? ?? 0;
    final projectsActive = projectsSection['projects_active'] as int? ?? 0;
    final projectsDone = projectsSection['projects_done'] as int? ?? 0;
    final tasksActive = projectsSection['tasks_active'] as int? ?? 0;
    final tasksDone = projectsSection['tasks_done'] as int? ?? 0;
    final activeProjects =
        projectsSection['active_project_names'] as List? ?? const [];
    final activeTasks =
        projectsSection['active_task_titles'] as List? ?? const [];

    final moodEmpty = _label(locale, 'No mood logged today.', 'Chưa ghi mood hôm nay.');
    final projectsEmpty =
        _label(locale, 'No active projects.', 'Không có dự án đang chạy.');
    final tasksEmpty =
        _label(locale, 'No active tasks.', 'Không có task đang mở.');

    return {
      'period_label': periodLabel,
      'net_today': _money(finance, net),
      'income_today': _money(finance, income),
      'expense_today': _money(finance, expense),
      'net_worth': _money(finance, netWorth),
      'month_income': _money(finance, monthlyIncome),
      'month_spending': _money(finance, monthlySpending),
      'month_net': _money(finance, monthlyNet),
      'daily_delta': _money(finance, dailyDelta),
      'total_savings': _money(finance, totalSavings),
      'remaining_budget': _money(finance, remainingBudget),
      'budget_usage': '${budgetUsage.toStringAsFixed(0)}%',
      'savings_rate': '${savingsRate.toStringAsFixed(1)}%',
      'drawdown': '${drawdown.toStringAsFixed(1)}%',
      'transactions_today': '$transactionCount',
      'subscriptions_count': '$subscriptionCount',
      'today_transactions_text': txBlock,
      'steps_display': _ratio(steps, stepGoal),
      'steps_progress': '${(healthSection['steps_progress_percent'] as num?)?.toStringAsFixed(0) ?? '0'}%',
      'sleep_display': _ratio(sleep, sleepGoal, unit: ' h'),
      'sleep_progress': '${(healthSection['sleep_progress_percent'] as num?)?.toStringAsFixed(0) ?? '0'}%',
      'water_display': _ratio(water, waterGoal, unit: ' ml'),
      'water_progress': '${(healthSection['water_progress_percent'] as num?)?.toStringAsFixed(0) ?? '0'}%',
      'heart_rate_display': _optionalNum(hr, suffix: ' bpm'),
      'oxygen_display': _optionalDouble(spo2, suffix: '%'),
      'calories_burned_display': _optionalNum(kcalBurned, suffix: ' kcal'),
      'calories_consumed_display': _ratio(kcalConsumed, kcalGoal, unit: ' kcal'),
      'exercise_display': _ratio(exercise, exerciseGoal, unit: ' min'),
      'focus_display': _ratio(focus, focusGoal, unit: ' min'),
      'weight_display': weight > 0
          ? '${weight.toStringAsFixed(1)} kg'
          : _label(locale, '—', '—'),
      'mood_display': hasMoodToday && moodScore != null
          ? '${moodLabel(moodScore, locale)} ($moodScore/5)'
          : moodEmpty,
      'mood_activities_display': hasMoodToday && moodActivities.isNotEmpty
          ? moodActivities.join(', ')
          : _label(locale, '—', '—'),
      'mood_note_display': hasMoodToday &&
              moodNote != null &&
              moodNote.trim().isNotEmpty
          ? moodNote.trim()
          : _label(locale, '—', '—'),
      'projects_summary':
          '$projectsActive ${_label(locale, 'active', 'đang chạy')} · $projectsDone ${_label(locale, 'done', 'xong')} · $projectsTotal ${_label(locale, 'total', 'tổng')}',
      'tasks_summary':
          '$tasksActive ${_label(locale, 'active', 'đang mở')} · $tasksDone ${_label(locale, 'done', 'xong')}',
      'projects_active_list': formatNameList(
        locale: locale,
        names: activeProjects,
        emptyMessage: projectsEmpty,
      ),
      'tasks_active_list': formatNameList(
        locale: locale,
        names: activeTasks,
        emptyMessage: tasksEmpty,
      ),
      'projects_active_list_multiline': formatNameListMultiline(
        names: activeProjects,
        emptyMessage: projectsEmpty,
      ),
      'tasks_active_list_multiline': formatNameListMultiline(
        names: activeTasks,
        emptyMessage: tasksEmpty,
      ),
    };
  }

  static String buildSubject({
    required String locale,
    required String periodLabel,
    String? recipientName,
  }) {
    final hello = recipientName != null && recipientName.trim().isNotEmpty
        ? recipientName.trim()
        : _label(locale, 'there', 'bạn');
    return _label(
      locale,
      'Daily summary — $periodLabel ($hello)',
      'Tóm tắt ngày — $periodLabel ($hello)',
    );
  }

  static String buildPlainText({
    required String locale,
    required Map<String, String> f,
  }) {
    final financeTitle = _label(locale, 'Finance', 'Tài chính');
    final healthTitle = _label(locale, 'Health', 'Sức khỏe');
    final moodTitle = _label(locale, 'Mood', 'Tâm trạng');
    final projectsTitle = _label(locale, 'Projects', 'Dự án');
    final txTitle = _label(locale, "Today's transactions", 'Giao dịch hôm nay');

    final lines = <String>[
      '${_label(locale, 'Daily summary', 'Tóm tắt ngày')} — ${f['period_label']}',
      '',
      financeTitle,
      '• ${_label(locale, 'Net today', 'Chênh lệch hôm nay')}: ${f['net_today']}',
      '• ${_label(locale, 'Income today', 'Thu nhập hôm nay')}: ${f['income_today']}',
      '• ${_label(locale, 'Spending today', 'Chi tiêu hôm nay')}: ${f['expense_today']}',
      '• ${_label(locale, 'Net worth', 'Tài sản ròng')}: ${f['net_worth']}',
      '• ${_label(locale, 'Month income', 'Thu nhập tháng')}: ${f['month_income']}',
      '• ${_label(locale, 'Month spending', 'Chi tiêu tháng')}: ${f['month_spending']}',
      '• ${_label(locale, 'Month net', 'Ròng tháng')}: ${f['month_net']}',
      '• ${_label(locale, 'Total savings', 'Tiết kiệm')}: ${f['total_savings']}',
      '• ${_label(locale, 'Daily delta', 'Biến động ngày')}: ${f['daily_delta']}',
      '• ${_label(locale, 'Remaining budget', 'Ngân sách còn')}: ${f['remaining_budget']}',
      '• ${_label(locale, 'Budget used', 'Đã dùng ngân sách')}: ${f['budget_usage']}',
      '• ${_label(locale, 'Savings rate', 'Tỷ lệ tiết kiệm')}: ${f['savings_rate']}',
      '• ${_label(locale, 'Drawdown', 'Drawdown')}: ${f['drawdown']}',
      '• ${_label(locale, 'Transactions today', 'Giao dịch hôm nay')}: ${f['transactions_today']}',
      '• ${_label(locale, 'Subscriptions', 'Đăng ký')}: ${f['subscriptions_count']}',
      '',
      healthTitle,
      '• ${_label(locale, 'Steps', 'Bước chân')}: ${f['steps_display']} (${f['steps_progress']})',
      '• ${_label(locale, 'Sleep', 'Giấc ngủ')}: ${f['sleep_display']} (${f['sleep_progress']})',
      '• ${_label(locale, 'Water', 'Nước')}: ${f['water_display']} (${f['water_progress']})',
      '• ${_label(locale, 'Heart rate', 'Nhịp tim')}: ${f['heart_rate_display']}',
      '• ${_label(locale, 'Blood oxygen', 'SpO₂')}: ${f['oxygen_display']}',
      '• ${_label(locale, 'Calories burned', 'Calo đốt')}: ${f['calories_burned_display']}',
      '• ${_label(locale, 'Calories consumed', 'Calo nạp')}: ${f['calories_consumed_display']}',
      '• ${_label(locale, 'Exercise', 'Tập luyện')}: ${f['exercise_display']}',
      '• ${_label(locale, 'Focus', 'Tập trung')}: ${f['focus_display']}',
      '• ${_label(locale, 'Weight', 'Cân nặng')}: ${f['weight_display']}',
      '',
      moodTitle,
      '• ${_label(locale, 'Today', 'Hôm nay')}: ${f['mood_display']}',
      '• ${_label(locale, 'Activities', 'Hoạt động')}: ${f['mood_activities_display']}',
      '• ${_label(locale, 'Note', 'Ghi chú')}: ${f['mood_note_display']}',
      '',
      projectsTitle,
      '• ${_label(locale, 'Projects', 'Dự án')}: ${f['projects_summary']}',
      '• ${_label(locale, 'Active projects', 'Dự án đang chạy')}:',
      f['projects_active_list_multiline']!,
      '• ${_label(locale, 'Tasks', 'Task')}: ${f['tasks_summary']}',
      '• ${_label(locale, 'Active tasks', 'Task đang mở')}:',
      f['tasks_active_list_multiline']!,
      '',
      txTitle,
      f['today_transactions_text']!,
    ];
    return lines.join(_nl);
  }

  static String plainToHtml(String plain) {
    final escaped = plain
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return escaped
        .replaceAll('\r\n', '<br>')
        .replaceAll('\n', '<br>')
        .replaceAll('\r', '<br>');
  }

  static String buildHtml({
    required String locale,
    required Map<String, String> f,
  }) {
    final plain = buildPlainText(locale: locale, f: f);
    final htmlBody = plainToHtml(plain).replaceAll(
      '<br><br>',
      '</p><p style="margin:14px 0 6px">',
    );
    return '<div style="font-family:system-ui,-apple-system,sans-serif;font-size:14px;line-height:1.6;color:#111">'
        '<p style="margin:0 0 6px">$htmlBody</p>'
        '</div>';
  }
}
