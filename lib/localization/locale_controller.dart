import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

class LocaleController extends ChangeNotifier {
  LocaleController() : _locale = AppLocalizations.fallbackLocale;

  static const String _localeKey = 'app_locale';

  Locale _locale;
  SharedPreferences? _preferences;

  Locale get locale => _locale;

  bool get isVietnamese => _locale.languageCode == 'vi';

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> loadSavedLocale() async {
    final prefs = await _getPreferences();
    final savedLanguageCode = prefs.getString(_localeKey);

    final savedLocale = savedLanguageCode != null
        ? Locale(savedLanguageCode)
        : null;
    final nextLocale =
        savedLocale != null && AppLocalizations.isSupported(savedLocale)
        ? savedLocale
        : AppLocalizations.resolveSupportedLocale(
            PlatformDispatcher.instance.locale,
          );

    final hasChanged = _locale.languageCode != nextLocale.languageCode;
    _locale = nextLocale;

    if (hasChanged) {
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    final nextLocale = AppLocalizations.resolveSupportedLocale(locale);

    final prefs = await _getPreferences();
    await prefs.setString(_localeKey, nextLocale.languageCode);

    final hasChanged = _locale.languageCode != nextLocale.languageCode;
    _locale = nextLocale;

    if (hasChanged) {
      notifyListeners();
    }
  }

  Future<void> setLanguageCode(String languageCode) {
    return setLocale(Locale(languageCode));
  }
}

final LocaleController localeController = LocaleController();
