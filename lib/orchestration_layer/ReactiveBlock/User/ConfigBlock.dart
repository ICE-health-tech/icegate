import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';

class ConfigBlock {
  late ConfigsDAO _dao;
  late String _personId;

  // Global Currency
  final currency = signal<String>('USD'); // Default to USD

  // Environmental Data Visibility
  final showAqi = signal<bool>(true);
  final showWeather = signal<bool>(true);

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
  }

  Future<void> setCurrency(String value) async {
    currency.value = value;
    if (_personId.isNotEmpty) {
      await _dao.setConfig(_personId, 'app_currency', value);
    }
  }

  // Helper for toggle (specific to currency for now)
  Future<void> toggleCurrency() async {
    final newValue = currency.value == 'USD' ? 'VND' : 'USD';
    await setCurrency(newValue);
  }

  Future<void> setAqiVisibility(bool visible) async {
    showAqi.value = visible;
    if (_personId.isNotEmpty) {
      await _dao.setConfig(_personId, 'show_aqi', visible.toString());
    }
  }

  Future<void> toggleAqi() async {
    await setAqiVisibility(!showAqi.value);
  }

  Future<void> setWeatherVisibility(bool visible) async {
    showWeather.value = visible;
    if (_personId.isNotEmpty) {
      await _dao.setConfig(_personId, 'show_weather', visible.toString());
    }
  }

  Future<void> toggleWeather() async {
    await setWeatherVisibility(!showWeather.value);
  }
}
