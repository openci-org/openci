import 'package:dashboard/connections/active_connection_api_client.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openci_api_client.g.dart';

@riverpod
Future<OpenCiApiService> openciApiService(Ref ref) async {
  final client = await ref.watch(activeConnectionApiClientProvider.future);
  return OpenCiApiService.create(client);
}
