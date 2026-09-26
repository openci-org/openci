import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'loki_labels.dart';
import 'loki_push_payload.dart';

String get _dateTimeNowNano =>
    (DateTime.now().toUtc().microsecondsSinceEpoch * 1000).toString();

Future<void> pushLogToLoki({
  required http.Client client,
  required String lokiUrl,
  required String message,
  required String stream,
  String? command,
}) => pushLogsToLoki(
  client: client,
  lokiUrl: lokiUrl,
  values: [
    [_dateTimeNowNano, message],
  ],
  stream: stream,
  command: command,
);

Future<void> pushLogsToLoki({
  required http.Client client,
  required String lokiUrl,
  required List<List<String>> values,
  required String stream,
  String? command,
}) async {
  final labels = LokiLabels.fromEnvironment(stream: stream, command: command);
  final payload = LokiPushPayload(
    streams: [LokiStream(labels: labels, values: values)],
  );

  final baseUri = Uri.parse(lokiUrl);
  final uri = baseUri.replace(
    path: '${baseUri.path.replaceFirst(RegExp(r'/+$'), '')}/loki/api/v1/push',
  );
  final response = await client.post(
    uri,
    headers: const {'content-type': 'application/json; charset=utf-8'},
    body: jsonEncode(payload.toMap()),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final responseBody = utf8.decode(response.bodyBytes);
    throw HttpException(
      'Failed to push log to Loki (HTTP ${response.statusCode}): $responseBody',
      uri: response.request?.url ?? uri,
    );
  }
}
