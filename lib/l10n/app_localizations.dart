import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'appTitle': 'CardChecks Diagram',
      'login': 'Login',
      'password': 'Password',
      'token': 'Token',
      'loginButton': 'Login',
      'dateRange': 'Date range',
      'selectDateRange': 'Select date range',
      'noData': 'No data to display',
      'error': 'Error',
      'sum': 'Sum',
      'shop': 'Shop',
      'address': 'Address',
      'changeLanguage': 'Change language',
      'logout': 'Logout',
    },
    'uk': {
      'appTitle': 'Діаграма Чеків',
      'login': 'Логін',
      'password': 'Пароль',
      'token': 'Токен',
      'loginButton': 'Увійти',
      'dateRange': 'Період дат',
      'selectDateRange': 'Оберіть період дат',
      'noData': 'Немає даних для відображення',
      'error': 'Помилка',
      'sum': 'Сума',
      'shop': 'Магазин',
      'address': 'Адреса',
      'changeLanguage': 'Змінити мову',
      'logout': 'Вийти',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'uk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
} 