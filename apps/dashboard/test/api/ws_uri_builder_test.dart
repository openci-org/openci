import 'package:dashboard/api/ws_uri_builder.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/active_connection_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openci_shared/openci_shared.dart';

void main() {
  test('rebuilds the WebSocket URI when the API client changes', () async {
    var baseUrl = 'https://cloud.example.com';
    final container = ProviderContainer.test(
      overrides: [
        activeConnectionApiClientProvider.overrideWith((ref) async {
          final client = createOpenCIChopperClient(
            baseUrl: baseUrl,
            tokenProvider: () => 'test-token',
          );
          ref.onDispose(client.dispose);
          return client;
        }),
        authedFirebaseIdTokenProvider.overrideWith(
          (ref) async => 'test-token',
        ),
      ],
    );
    final uriProvider = FutureProvider<Uri>(
      (ref) => buildAuthedWebSocketUri(
        ref,
        '/builds/commits/stream',
        queryParameters: {'teamId': 'team-123'},
      ),
    );
    container.listen(uriProvider, (_, _) {});

    expect(
      (await container.read(uriProvider.future)).toString(),
      'wss://cloud.example.com/builds/commits/stream'
      '?token=test-token&teamId=team-123',
    );

    baseUrl = 'http://self-hosted.example.com:8080';
    container.invalidate(activeConnectionApiClientProvider);

    expect(
      (await container.read(uriProvider.future)).toString(),
      'ws://self-hosted.example.com:8080/builds/commits/stream'
      '?token=test-token&teamId=team-123',
    );
  });
}
