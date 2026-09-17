import 'package:chopper/chopper.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/utilities/openci_server_url_provider.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openci_api_client.g.dart';

@riverpod
Future<ChopperClient> openciApiClient(Ref ref) async {
  final baseUrl = ref.watch(openciServerUrlProvider);
  final auth = ref.watch(firebaseAuthProvider);

  return createOpenCiChopperClient(
    baseUrl: baseUrl,
    tokenProvider: () {
      final user = auth.currentUser;
      if (user == null) return null;
      return user.getIdToken();
    },
  );
}

@riverpod
Future<OpenCiApiService> openciApiService(Ref ref) async {
  final client = await ref.watch(openciApiClientProvider.future);
  return OpenCiApiService.create(client);
}
