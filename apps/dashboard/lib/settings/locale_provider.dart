import 'package:dashboard/i18n/strings.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';

final localeProvider = AsyncNotifierProvider<LocaleNotifier, String?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  Future<void> setLocale(String? localeTag) async {
    final prefs = await SharedPreferences.getInstance();
    if (localeTag == null) {
      await prefs.remove(_localeKey);
      await LocaleSettings.useDeviceLocale();
    } else {
      await prefs.setString(_localeKey, localeTag);
      LocaleSettings.setLocaleRaw(localeTag);
    }
    state = AsyncValue.data(localeTag);
  }
}
