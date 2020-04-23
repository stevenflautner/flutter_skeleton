import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_skeleton/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locator.dart';

//text(String key) => get<Localizator>().localization.text(key);

extension TextLocalization on String {
  String localized() => get<Localizator>().localization.text(this) ?? this;
}

class Localization {

  final Locale locale;
  final Map<String, dynamic> _strings;

  Localization(this.locale, this._strings);

  String text(String key) => _strings[key];

}

class Localizator extends LocalizationsDelegate<Localization> {

  final List<String> supportedCodes;
  Localization localization;

  Localizator({ @required this.supportedCodes });

  @override
  bool isSupported(Locale locale) => supportedCodes.contains(locale.languageCode);

  static Locale forcedLocale() {
    final stored = get<SharedPreferences>().getString('languageCode');
    return stored != null ? Locale(stored) : null;
  }

  @override
  Future<Localization> load(Locale locale) async {
    if (localization == null)
      await _load(locale);

    return localization;
  }

  Future<void> _load(Locale locale) async {
    this.localization = Localization(
      locale,
      jsonDecode(
        await rootBundle.loadString('lang/${locale.languageCode}.json')
      )
    );
  }

  void changeLanguage(BuildContext context, String languageCode) async {
    get<SharedPreferences>().setString('languageCode', languageCode);
    await _load(Locale(languageCode));
    App.of(context).rebuild();
  }

  @override
  bool shouldReload(Localizator old) => false;

  Iterable<Locale> get supportedLocales => supportedCodes.map((code) => Locale(code));

}