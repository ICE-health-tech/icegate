import 'dart:convert';

import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

class ConfigBlock {
  late ConfigsDAO _dao;
  late String _personId;

  // Global Currency
  final currency = signal<String>('USD'); // Default to USD

  // Environmental Data Visibility
  final showAqi = signal<bool>(true);
  final showWeather = signal<bool>(true);

  // Home Page Indices Visibility
  final showIndexSteps = signal<bool>(true);
  final showIndexCalories = signal<bool>(true);
  final showIndexBalance = signal<bool>(true);
  final showIndexSpending = signal<bool>(true);
  final showIndexMood = signal<bool>(true);
  final showIndexProjects = signal<bool>(true);
  final showIndexWater = signal<bool>(true);
  final showIndexWeight = signal<bool>(true);
  final showIndexFinanceDaily = signal<bool>(true);
  final showIndexFinanceUsage = signal<bool>(true);
  final showIndexFocus = signal<bool>(true);
  final showIndexMoodNote = signal<bool>(true);

  /// `subId|yyyy-MM` tokens — hide a charge from the future plan for that month only.
  final subscriptionPlanSkips = signal<Set<String>>({});

  static const _subscriptionPlanSkipsKey = 'subscription_plan_skips';

  void init(ConfigsDAO dao, String personId) async {
    _dao = dao;
    _personId = personId;

    if (_personId.isEmpty) return;

    // Load initial settings
    _loadAllConfigs();
  }

  Future<void> _loadAllConfigs() async {
    final currencyConfig = await _dao.getConfig(_personId, 'app_currency');
    if (currencyConfig != null) {
      currency.value = currencyConfig.configValue;
    }

    final aqiConfig = await _dao.getConfig(_personId, 'show_aqi');
    if (aqiConfig != null) {
      showAqi.value = aqiConfig.configValue == 'true';
    }

    final weatherConfig = await _dao.getConfig(_personId, 'show_weather');
    if (weatherConfig != null) {
      showWeather.value = weatherConfig.configValue == 'true';
    }

    // Load Indices
    showIndexSteps.value = await _getBoolConfig('show_index_steps', true);
    showIndexCalories.value = await _getBoolConfig('show_index_calories', true);
    showIndexBalance.value = await _getBoolConfig('show_index_balance', true);
    showIndexSpending.value = await _getBoolConfig('show_index_spending', true);
    showIndexMood.value = await _getBoolConfig('show_index_mood', true);
    showIndexProjects.value = await _getBoolConfig('show_index_projects', true);
    showIndexWater.value = await _getBoolConfig('show_index_water', true);
    showIndexWeight.value = await _getBoolConfig('show_index_weight', true);
    showIndexFinanceDaily.value = await _getBoolConfig('show_index_finance_daily', true);
    showIndexFinanceUsage.value = await _getBoolConfig('show_index_finance_usage', true);
    showIndexFocus.value = await _getBoolConfig('show_index_focus', true);
    showIndexMoodNote.value = await _getBoolConfig('show_index_mood_note', true);

    await _loadSubscriptionPlanSkips();
  }

  static String subscriptionPlanSkipToken(
    String subId,
    int year,
    int month,
  ) {
    return '$subId|${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSubscriptionPlanSkips() async {
    final config = await _dao.getConfig(_personId, _subscriptionPlanSkipsKey);
    if (config == null) return;
    try {
      final decoded = jsonDecode(config.configValue);
      if (decoded is! List) return;
      final pruned = _pruneSubscriptionPlanSkips(
        decoded.map((e) => e.toString()).toList(),
      );
      subscriptionPlanSkips.value = pruned;
      if (pruned.length != decoded.length) {
        await _persistSubscriptionPlanSkips(pruned);
      }
    } catch (_) {
      subscriptionPlanSkips.value = {};
    }
  }

  Set<String> _pruneSubscriptionPlanSkips(List<String> tokens) {
    final now = DateTime.now();
    final currentYm =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    return tokens.where((token) {
      final parts = token.split('|');
      if (parts.length != 2) return false;
      return parts[1].compareTo(currentYm) >= 0;
    }).toSet();
  }

  Future<void> _persistSubscriptionPlanSkips(Set<String> tokens) async {
    if (_personId.isEmpty) return;
    await _dao.setConfig(
      _personId,
      _subscriptionPlanSkipsKey,
      jsonEncode(tokens.toList()..sort()),
    );
  }

  bool isSubscriptionSkippedForPlanMonth(
    String subId,
    int year,
    int month,
  ) {
    return subscriptionPlanSkips.value.contains(
      subscriptionPlanSkipToken(subId, year, month),
    );
  }

  Future<void> skipSubscriptionForPlanMonth(
    String subId,
    int year,
    int month,
  ) async {
    if (_personId.isEmpty) return;
    final next = {
      ...subscriptionPlanSkips.value,
      subscriptionPlanSkipToken(subId, year, month),
    };
    subscriptionPlanSkips.value = next;
    await _persistSubscriptionPlanSkips(next);
  }

  Future<bool> _getBoolConfig(String key, bool defaultValue) async {
    final config = await _dao.getConfig(_personId, key);
    if (config == null) return defaultValue;
    return config.configValue == 'true';
  }

  Future<void> _setBoolConfig(String key, bool value) async {
    if (_personId.isNotEmpty) {
      await _dao.setConfig(_personId, key, value.toString());
    }
  }

  Future<void> setIndexVisibility(String key, bool visible) async {
    switch (key) {
      case 'steps':
        showIndexSteps.value = visible;
        await _setBoolConfig('show_index_steps', visible);
        break;
      case 'calories':
        showIndexCalories.value = visible;
        await _setBoolConfig('show_index_calories', visible);
        break;
      case 'balance':
        showIndexBalance.value = visible;
        await _setBoolConfig('show_index_balance', visible);
        break;
      case 'spending':
        showIndexSpending.value = visible;
        await _setBoolConfig('show_index_spending', visible);
        break;
      case 'mood':
        showIndexMood.value = visible;
        await _setBoolConfig('show_index_mood', visible);
        break;
      case 'projects':
        showIndexProjects.value = visible;
        await _setBoolConfig('show_index_projects', visible);
        break;
      case 'water':
        showIndexWater.value = visible;
        await _setBoolConfig('show_index_water', visible);
        break;
      case 'weight':
        showIndexWeight.value = visible;
        await _setBoolConfig('show_index_weight', visible);
        break;
      case 'financeDaily':
        showIndexFinanceDaily.value = visible;
        await _setBoolConfig('show_index_finance_daily', visible);
        break;
      case 'financeUsage':
        showIndexFinanceUsage.value = visible;
        await _setBoolConfig('show_index_finance_usage', visible);
        break;
      case 'focus':
        showIndexFocus.value = visible;
        await _setBoolConfig('show_index_focus', visible);
        break;
      case 'mood_note':
        showIndexMoodNote.value = visible;
        await _setBoolConfig('show_index_mood_note', visible);
        break;
    }
  }

  Future<void> setCurrency(String value) async {
    currency.value = value;
    if (_personId.isNotEmpty) {
      await _dao.setConfig(_personId, 'app_currency', value);
    }
  }

  Future<void> toggleCurrency() async {
    final newValue = currency.value == 'USD' ? 'VND' : 'USD';
    await setCurrency(newValue);
  }

  Future<void> setAqiVisibility(bool visible) async {
    showAqi.value = visible;
    await _setBoolConfig('show_aqi', visible);
  }

  Future<void> toggleAqi() async {
    await setAqiVisibility(!showAqi.value);
  }

  Future<void> setWeatherVisibility(bool visible) async {
    showWeather.value = visible;
    await _setBoolConfig('show_weather', visible);
  }

  Future<void> toggleWeather() async {
    await setWeatherVisibility(!showWeather.value);
  }
}
