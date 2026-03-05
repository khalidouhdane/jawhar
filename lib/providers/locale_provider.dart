import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app locale. Persists the user's choice.
/// On first launch, auto-detects the phone language.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';
  final SharedPreferences _prefs;
  late Locale _locale;

  LocaleProvider(this._prefs) {
    final saved = _prefs.getString(_key);
    if (saved != null) {
      _locale = Locale(saved);
    } else {
      // First launch: detect phone language
      final systemLang = ui.PlatformDispatcher.instance.locale.languageCode;
      _locale = systemLang == 'ar' ? const Locale('ar') : const Locale('en');
    }
  }

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    _prefs.setString(_key, locale.languageCode);
    notifyListeners();
  }

  void toggleLocale() {
    setLocale(isArabic ? const Locale('en') : const Locale('ar'));
  }
}
