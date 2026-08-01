import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openci_shared/openci_shared.dart' as shared;

Future<Uri> buildAuthedWebSocketUri(
  Ref ref,
  String path, {
  Map<String, String>? queryParameters,
}) async {
  final api = ref.read(openciApiServiceProvider);
  final token = await ref.watch(authedFirebaseIdTokenProvider.future);

  final baseUrl = api.client.baseUrl.toString();

  final params = <String, String>{
    if (token.isNotEmpty) 'token': token,
    ...?queryParameters,
  };

  return shared.buildWebSocketUri(baseUrl, path, queryParameters: params);
}
