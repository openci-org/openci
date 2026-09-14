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

  @override
  Future<Response<Map<String, dynamic>>> queryRange({
    required String query,
    required String start,
    required int limit,
    required String direction,
  }) {
    final Uri $url = Uri.parse('/loki/api/v1/query_range');
    final Map<String, dynamic> $params = <String, dynamic>{
      'query': query,
      'start': start,
      'limit': limit,
      'direction': direction,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<Map<String, dynamic>, Map<String, dynamic>>(
      $request,
      responseConverter: LokiApiService._decodeQueryRangeResponse,
    );
  }
}
