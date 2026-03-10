import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// LocaleBlock quản lý ngôn ngữ hiện tại của ứng dụng.
/// Sử dụng SharedPreferences để lưu trữ lựa chọn ngôn ngữ.
/// Sử dụng signals để thông báo thay đổi ngôn ngữ cho toàn bộ ứng dụng.
class LocaleBlock {
  // Key dùng để lưu trữ ngôn ngữ trong SharedPreferences
  static const String _localeKey = 'app_locale';

  // Ngôn ngữ mặc định là tiếng Việt
  static const Locale _defaultLocale = Locale('vi', 'VN');

  // Danh sách ngôn ngữ hỗ trợ
  static const List<Locale> supportedLocales = [
    Locale('vi', 'VN'),
    Locale('en'),
  ];

  // Tên hiển thị của mỗi ngôn ngữ
  static const Map<String, String> localeNames = {
    'vi': 'Tiếng Việt',
    'en': 'English',
  };

  // Signal reactive cho ngôn ngữ hiện tại
  final Signal<Locale> currentLocale = signal(_defaultLocale);

  /// Khởi tạo: đọc ngôn ngữ đã lưu từ SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      // Tìm locale tương ứng từ danh sách hỗ trợ
      final locale = supportedLocales.firstWhere(
        (l) => l.languageCode == savedLocale,
        orElse: () => _defaultLocale,
      );
      currentLocale.value = locale;
    }
  }

  /// Thay đổi ngôn ngữ và lưu vào SharedPreferences
  Future<void> setLocale(Locale locale) async {
    currentLocale.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// Lấy tên hiển thị của ngôn ngữ hiện tại
  String get currentLocaleName {
    return localeNames[currentLocale.value.languageCode] ?? 'Unknown';
  }

  /// Lấy tên hiển thị của một locale bất kỳ
  String getLocaleName(Locale locale) {
    return localeNames[locale.languageCode] ?? locale.languageCode;
  }
}
