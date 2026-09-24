import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

class LokiService {
  final String lokiUrl;
  final http.Client _client;

  LokiService({
    String? lokiUrl,
    http.Client? client,
  }) : lokiUrl =
           lokiUrl ??
           Platform.environment['LOKI_URL'] ??
           'http://localhost:3100',
       _client = client ?? http.Client();

  Future<List<String>> getLogsForRun({
    required String runId,
    String? stepId,
    int limit = 5000,
  }) async {
    final querySelector = stepId != null && stepId.isNotEmpty
        ? '{run_id="$runId", step_id="$stepId", type!="step_event"}'
        : '{run_id="$runId", type!="step_event"}';

    final sevenDaysAgoNano =
        BigInt.from(
          DateTime.now()
              .toUtc()
              .subtract(const Duration(days: 7))
              .microsecondsSinceEpoch,
        ) *
        BigInt.from(1000);

    final chopperClient = ChopperClient(
      baseUrl: Uri.parse(lokiUrl),
      client: _client,
      converter: const JsonConverter(),
    );

    try {
      final response = await LokiApiService.create(chopperClient)
          .queryRange(
            query: querySelector,
            start: sevenDaysAgoNano.toString(),
            limit: limit,
            direction: 'FORWARD',
          )
          .whenComplete(chopperClient.dispose)
          .timeout(const Duration(seconds: 10));
      final uri = response.base.request?.url;

      if (response.statusCode != 200) {
        throw HttpException(
          'Loki query failed with status ${response.statusCode}: ${response.bodyString}',
          uri: uri,
        );
      }

      final json = response.body!;
      final status = json['status'] as String?;
      if (status != 'success') {
        throw HttpException('Loki query failed: $status', uri: uri);
      }

      final data = json['data'] as Map<String, dynamic>?;
      final result = data?['result'] as List<dynamic>?;
      if (result == null) {
        throw const FormatException('Missing Loki query results');
      }
      if (result.isEmpty) return [];

      final List<MapEntry<int, String>> timedLines = [];

      for (final streamItem in result) {
        if (streamItem is! Map<String, dynamic>) continue;
        final values = streamItem['values'] as List<dynamic>?;
        if (values == null) continue;

        for (final entry in values) {
          if (entry is List && entry.length >= 2) {
            final nanoStr = entry[0].toString();
            final message = entry[1].toString();
            final timestamp = int.tryParse(nanoStr) ?? 0;
            timedLines.add(MapEntry(timestamp, message));
          }
        }
      }

      timedLines.sort((a, b) => a.key.compareTo(b.key));

      return timedLines.map((e) => e.value).toList();
    } catch (e, s) {
      stderr.writeln(
        '[LokiService] Error querying Loki for runId $runId: $e\n$s',
      );
      rethrow;
    }
  }

  Future<List<BuildStep>> getStepSummariesForRun({
    required String runId,
  }) async {
    final querySelector = '{run_id="$runId", type="step_event"}';

    final sevenDaysAgoNano =
        BigInt.from(
          DateTime.now()
              .toUtc()
              .subtract(const Duration(days: 7))
              .microsecondsSinceEpoch,
        ) *
        BigInt.from(1000);

    final chopperClient = ChopperClient(
      baseUrl: Uri.parse(lokiUrl),
      client: _client,
      converter: const JsonConverter(),
    );

    try {
      stderr.writeln(
        '[LokiService] Querying Loki step events for runId $runId',
      );
      final response = await LokiApiService.create(chopperClient)
          .queryRange(
            query: querySelector,
            start: sevenDaysAgoNano.toString(),
            limit: 1000,
            direction: 'FORWARD',
          )
          .whenComplete(chopperClient.dispose)
          .timeout(const Duration(seconds: 10));
      final uri = response.base.request?.url;

      stderr.writeln(
        '[LokiService] Loki response status: ${response.statusCode}, body: ${response.bodyString}',
      );

      if (response.statusCode != 200) {
        throw HttpException(
          'Loki step query failed with status ${response.statusCode}: ${response.bodyString}',
          uri: uri,
        );
      }

      final json = response.body!;
      final status = json['status'] as String?;
      if (status != 'success') {
        throw HttpException('Loki step query failed: $status', uri: uri);
      }

      final data = json['data'] as Map<String, dynamic>?;
      final result = data?['result'] as List<dynamic>?;
      if (result == null) {
        throw const FormatException('Missing Loki query results');
      }
      if (result.isEmpty) return [];

      final Map<String, BuildStep> stepsById = {};

      for (final streamItem in result) {
        if (streamItem is! Map<String, dynamic>) continue;
        final values = streamItem['values'] as List<dynamic>?;
        if (values == null) continue;

        for (final entry in values) {
          if (entry is List && entry.length >= 2) {
            final rawJson = entry[1].toString();
            try {
              final stepData = jsonDecode(rawJson) as Map<String, dynamic>;
              final rawStatus = stepData['status']?.toString().toUpperCase();
              if (rawStatus == 'RUNNING') {
                stepData['status'] = BuildJobStatus.IN_PROGRESS.name;
              }
              final step = BuildStep.fromJson(stepData);
              if (step.id.isNotEmpty) {
                stepsById[step.id] = step;
              }
            } catch (_) {}
          }
        }
      }

      final stepList = stepsById.values.toList();
      stepList.sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

      return stepList;
    } catch (e, s) {
      stderr.writeln(
        '[LokiService] Error querying step summaries for runId $runId: $e\n$s',
      );
      rethrow;
    }
  }

  static List<MapEntry<Map<String, String>, String>> parseTailFrame(
    String frameJsonStr,
  ) {
    final List<MapEntry<Map<String, String>, String>> results = [];
    try {
      final json = jsonDecode(frameJsonStr) as Map<String, dynamic>;
      final streams = json['streams'] as List<dynamic>?;
      if (streams == null) return results;

      for (final streamItem in streams) {
        if (streamItem is! Map<String, dynamic>) continue;
        final rawStream = streamItem['stream'] as Map<String, dynamic>? ?? {};
        final labels = rawStream.map((k, v) => MapEntry(k, v.toString()));

        final values = streamItem['values'] as List<dynamic>?;
        if (values == null) continue;

        for (final entry in values) {
          if (entry is List && entry.length >= 2) {
            final message = entry[1].toString();
            results.add(MapEntry(labels, message));
          }
        }
      }
    } catch (_) {}
    return results;
  }
}
