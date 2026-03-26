import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late Map<String, String> _localizedStrings;

  static const Locale fallbackLocale = Locale('ru');
  static const List<Locale> supportedLocales = [
    Locale('ru'),
    Locale('vi'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'AppLocalizations is not available.');
    return localizations!;
  }

  static bool isSupported(Locale locale) {
    return supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  static Locale resolveSupportedLocale(Locale locale) {
    if (!isSupported(locale)) {
      return fallbackLocale;
    }
    return Locale(locale.languageCode);
  }

  Future<bool> load() async {
    final languageCode = resolveSupportedLocale(locale).languageCode;
    final fallbackStrings = await _loadStringsForLocale(
      fallbackLocale.languageCode,
    );

    if (languageCode == fallbackLocale.languageCode) {
      _localizedStrings = fallbackStrings;
      return true;
    }

    final localizedStrings = await _loadStringsForLocale(languageCode);
    _localizedStrings = {
      ...fallbackStrings,
      ...localizedStrings,
    };
    return true;
  }

  Future<Map<String, String>> _loadStringsForLocale(String languageCode) async {
    final jsonString = await rootBundle.loadString(
      'assets/lang/$languageCode.json',
    );
    final Map<String, dynamic> jsonMap =
        json.decode(jsonString) as Map<String, dynamic>;

    return jsonMap.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  String t(
    String key, {
    Map<String, String> params = const {},
  }) {
    var value = _localizedStrings[key] ?? key;
    params.forEach((paramKey, paramValue) {
      value = value.replaceAll('{$paramKey}', paramValue);
    });
    return value;
  }

  String languageName(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'vi':
        return t('language.vietnamese');
      case 'en':
      case 'english':
      case 'английский':
        return t('language.english');
      case 'ru':
      case 'russian':
      case 'русский':
        return t('language.russian');
      default:
        return languageCode;
    }
  }

  String bookLanguageName(String language) {
    final normalized = language.trim().toLowerCase();
    switch (normalized) {
      case 'vi':
      case 'vietnamese':
      case 'tiếng việt':
      case 'вьетнамский':
        return t('language.vietnamese');
      case 'en':
      case 'english':
      case 'английский':
        return t('language.english');
      case 'ru':
      case 'russian':
      case 'русский':
        return t('language.russian');
      default:
        return language;
    }
  }

  String genderName(String gender) {
    final normalized = gender.trim().toLowerCase();
    switch (normalized) {
      case 'male':
      case 'мужской':
      case 'nam':
        return t('gender.male');
      case 'female':
      case 'женский':
      case 'nữ':
      case 'nu':
        return t('gender.female');
      default:
        return gender;
    }
  }

  String roleName(String role) {
    switch (role.trim().toLowerCase()) {
      case 'reader':
        return t('role.reader');
      case 'librarian':
        return t('role.librarian');
      default:
        return role;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContextExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(
    String key, {
    Map<String, String> params = const {},
  }) {
    return l10n.t(key, params: params);
  }
}
