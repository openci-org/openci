import 'package:dashboard/app_strings.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const localePreferenceKey = 'dashboard_language';

AppLocale? savedLocale(SharedPreferences preferences) =>
    switch (preferences.getString(localePreferenceKey)) {
      'en' => AppLocale.en,
      'ja' => AppLocale.ja,
      _ => null,
    };

void initializeLocale(SharedPreferences preferences) {
  final locale = savedLocale(preferences);
  if (locale == null) {
    LocaleSettings.useDeviceLocaleSync();
  } else {
    LocaleSettings.setLocaleSync(locale);
  }
}

final localePreferenceProvider = NotifierProvider<LocalePreference, AppLocale?>(
  LocalePreference.new,
);

class LocalePreference extends Notifier<AppLocale?> {
  int _saveGeneration = 0;

  @override
  AppLocale? build() => savedLocale(ref.watch(sharedPreferencesProvider));

  Future<void> setLocale(AppLocale? locale) async {
    final generation = ++_saveGeneration;
    final preferences = ref.read(sharedPreferencesProvider);
    final saved = locale == null
        ? await preferences.remove(localePreferenceKey)
        : await preferences.setString(localePreferenceKey, locale.languageCode);
    if (!saved) throw StateError('Could not save language preference');
    if (!ref.mounted || generation != _saveGeneration) return;
    if (locale == null) {
      LocaleSettings.useDeviceLocaleSync();
    } else {
      LocaleSettings.setLocaleSync(locale);
    }
    state = locale;
  }
}
