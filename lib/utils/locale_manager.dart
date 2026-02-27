import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleManager {
  static final LocaleManager _instance = LocaleManager._internal();
  factory LocaleManager() => _instance;
  LocaleManager._internal();

  final _storage = const FlutterSecureStorage();
  static const String _localeKey = 'app_locale';

  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  Future<void> init() async {
    String? code = await _storage.read(key: _localeKey);
    if (code != null) {
      locale.value = Locale(code);
    }
  }

  Future<void> setLocale(String languageCode) async {
    locale.value = Locale(languageCode);
    await _storage.write(key: _localeKey, value: languageCode);
  }

  String get languageName {
    switch (locale.value.languageCode) {
      case 'hi':
        return 'हिन्दी';
      case 'te':
        return 'తెలుగు';
      case 'ta':
        return 'தமிழ்';
      case 'kn':
        return 'ಕನ್ನಡ';
      default:
        return 'English';
    }
  }
}
