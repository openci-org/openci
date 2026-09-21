import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

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
  final labels = LokiLabels.fromEnvironment(
    stream: stream,
    command: command,
  );
  final payload = LokiPushPayload(
    streams: [LokiStream(labels: labels, values: values)],
  );

  final chopperClient = ChopperClient(
    baseUrl: Uri.parse(lokiUrl),
    client: client,
    converter: const JsonConverter(),
  );
  final api = LokiApiService.create(chopperClient);
  final response = await api
      .push(payload.toMap())
      .whenComplete(chopperClient.dispose);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final responseBody = utf8.decode(response.bodyBytes);
    throw HttpException(
      'Failed to push log to Loki (HTTP ${response.statusCode}): $responseBody',
      uri: response.base.request?.url,
    );
  }
}
