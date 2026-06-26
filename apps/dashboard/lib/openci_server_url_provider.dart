import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openci_server_url_provider.g.dart';

@riverpod
String openciServerUrl(Ref ref) {
  const serverUrl = String.fromEnvironment('OPENCI_SERVER_URL');
  if (serverUrl.isEmpty) {
    throw StateError('OPENCI_SERVER_URL is not set');
  }
  return serverUrl;
}
