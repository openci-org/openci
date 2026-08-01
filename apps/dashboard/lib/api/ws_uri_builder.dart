import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<Uri> buildWebSocketUri(
  Ref ref,
  String path, {
  Map<String, String>? queryParameters,
}) async {
  final api = ref.read(openciApiServiceProvider);
  final token = await ref.watch(authedFirebaseIdTokenProvider.future);

  final baseUrl = api.client.baseUrl.toString();
  final wsScheme = baseUrl.startsWith('https') ? 'wss' : 'ws';
  final host = baseUrl
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceAll('/', '');

  final params = <String, String>{
    if (token.isNotEmpty) 'token': token,
    ...?queryParameters,
  };

  return Uri(
    scheme: wsScheme,
    host: host.contains(':') ? host.split(':').first : host,
    port: host.contains(':') ? int.tryParse(host.split(':').last) : null,
    path: path,
    queryParameters: params.isNotEmpty ? params : null,
  );
}
