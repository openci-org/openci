// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'loki_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$LokiApiService extends LokiApiService {
  _$LokiApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = LokiApiService;

  @override
  Future<Response<void>> push(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/loki/api/v1/push');
    final Map<String, String> $headers = {
      'content-type': 'application/json; charset=utf-8',
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<void, void>($request);
  }
}
