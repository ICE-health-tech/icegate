import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

class ConfigBlock {
  late ConfigsDAO _dao;
  late String _personId;

  // Global Currency
  final currency = signal<String>('USD'); // Default to USD

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
      currency.value = currencyConfig.value;
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
}
