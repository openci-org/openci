import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openci_server_url_provider.g.dart';

const customServerUrlKey = 'custom_openci_server_url';

@riverpod
String openciServerUrl(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final customUrl = prefs.getString(customServerUrlKey);
  if (customUrl != null && customUrl.isNotEmpty) {
    return customUrl;
  }

  const serverUrl = String.fromEnvironment('OPENCI_SERVER_URL');
  if (serverUrl.isEmpty) {
    throw StateError('OPENCI_SERVER_URL is not set');
  }
  return serverUrl;
}

@riverpod
class CustomServerUrl extends _$CustomServerUrl {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(customServerUrlKey);
  }

  Future<void> setUrl(String url) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (url.trim().isEmpty) {
      await prefs.remove(customServerUrlKey);
      state = null;
    } else {
      await prefs.setString(customServerUrlKey, url.trim());
      state = url.trim();
    }
    ref.invalidate(openciServerUrlProvider);
  }

  Future<void> clearUrl() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(customServerUrlKey);
    state = null;
    ref.invalidate(openciServerUrlProvider);
  }
}
