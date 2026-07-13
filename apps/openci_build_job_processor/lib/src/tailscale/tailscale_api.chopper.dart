// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'tailscale_api.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$TailscaleApi extends TailscaleApi {
  _$TailscaleApi([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = TailscaleApi;

  @override
  Future<Response<TailscaleDevicesResponse>> getDevices({
    required String tailnet,
    required String authorization,
    String accept = 'application/json',
  }) {
    final Uri $url = Uri.parse(
      'https://api.tailscale.com/api/v2/tailnet/${tailnet}/devices',
    );
    final Map<String, String> $headers = {
      'Authorization': authorization,
      'Accept': accept,
    };
    final ChopperCompleter $abortTrigger = ChopperCompleter<void>();
    final ChopperTimer $timeout = ChopperTimer(
      const Duration(microseconds: 10000000),
      () {
        if (!$abortTrigger.isCompleted) $abortTrigger.complete();
      },
    );
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      headers: $headers,
      abortTrigger: $abortTrigger.future,
    );
    return client
        .send<TailscaleDevicesResponse, TailscaleDevicesResponse>($request)
        .catchError(
          (_) => Future<Response<TailscaleDevicesResponse>>.error(
            ChopperTimeoutException('Request timed out after 10 seconds'),
          ),
          test: (Object err) =>
              err is ChopperRequestAbortedException &&
              $abortTrigger.isCompleted,
        )
        .whenComplete($timeout.cancel);
  }
}
