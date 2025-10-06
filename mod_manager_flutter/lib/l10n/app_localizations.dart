import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late final Map<String, dynamic> _localizedValues;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? result = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(result != null, 'AppLocalizations has not been initialized.');
    return result!;
  }

  Future<void> load() async {
    final jsonString = await rootBundle.loadString('assets/l10n/${locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    _localizedValues = jsonMap;
  }

  String t(String key, {Map<String, String>? params, String? fallback}) {
    final segments = key.split('.');
    dynamic current = _localizedValues;

    for (final segment in segments) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return fallback ?? key;
      }
    }

    if (current is String) {
      var value = current;
      if (params != null) {
        params.forEach((placeholder, replacement) {
          value = value.replaceAll('{${placeholder}}', replacement);
        });
      }
      return value;
    }

    return fallback ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => const ['en', 'uk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
