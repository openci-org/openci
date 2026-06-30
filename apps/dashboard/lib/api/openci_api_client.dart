import 'package:chopper/chopper.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openci_api_client.g.dart';

@riverpod
ChopperClient openciApiClient(Ref ref) {
  final baseUrl = ref.watch(openciServerUrlProvider);
  final auth = ref.watch(firebaseAuthProvider);

  return createOpenCiChopperClient(
    baseUrl: baseUrl,
    tokenProvider: () async {
      final user = auth.currentUser;
      if (user == null) return null;
      try {
        return await user.getIdToken();
      } catch (_) {
        return null;
      }
    },
  );
}

@riverpod
OpenCiApiService openciApiService(Ref ref) {
  final client = ref.watch(openciApiClientProvider);
  return OpenCiApiService.create(client);
}
