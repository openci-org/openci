import 'dart:convert';
import 'dart:io';

import 'loki_labels.dart';
import 'loki_push_payload.dart';

Uri _lokiUri(String lokiUrl) => Uri.parse('$lokiUrl/loki/api/v1/push');

String get _dateTimeNowNano =>
    (DateTime.now().toUtc().microsecondsSinceEpoch * 1000).toString();

Future<void> pushLogToLoki({
  required HttpClient client,
  required String lokiUrl,
  required String message,
  required String stream,
  String? command,
}) async {
  final labels = LokiLabels.fromEnvironment(
    stream: stream,
    command: command,
  );
  final payload = LokiPushPayload.single(
    labels: labels,
    timestampNanos: _dateTimeNowNano,
    message: message,
  );

  final uri = _lokiUri(lokiUrl);
  final response = await _post(
    client: client,
    uri: uri,
    payload: payload,
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final responseBody = await response.transform(utf8.decoder).join();
    throw HttpException(
      'Failed to push log to Loki (HTTP ${response.statusCode}): $responseBody',
      uri: uri,
    );
  }
  await response.drain<void>();
}

Future<HttpClientResponse> _post({
  required HttpClient client,
  required Uri uri,
  required LokiPushPayload payload,
}) async {
  final request = await client.postUrl(uri);
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(payload.toMap()));
  return await request.close();
}
