import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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

  /// 指定した runId に関連するログ行を取得します
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

    final uri = Uri.parse('$lokiUrl/loki/api/v1/query_range').replace(
      queryParameters: {
        'query': querySelector,
        'limit': limit.toString(),
        'direction': 'FORWARD',
        'start': sevenDaysAgoNano.toString(),
      },
    );

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        stderr.writeln(
          '[LokiService] Loki query failed with status ${response.statusCode}: ${response.body}',
        );
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String?;
      if (status != 'success') return [];

      final data = json['data'] as Map<String, dynamic>?;
      final result = data?['result'] as List<dynamic>?;
      if (result == null || result.isEmpty) return [];

      final List<MapEntry<int, String>> timedLines = [];

      for (final streamItem in result) {
        if (streamItem is! Map<String, dynamic>) continue;
        final values = streamItem['values'] as List<dynamic>?;
        if (values == null) continue;

        for (final entry in values) {
          if (entry is List && entry.length >= 2) {
            final nanoStr = entry[0].toString();
            final message = entry[1].toString();
            if (message.trim().startsWith('{') &&
                (message.contains('"runId"') || message.contains('"status"'))) {
              continue;
            }
            final timestamp = int.tryParse(nanoStr) ?? 0;
            timedLines.add(MapEntry(timestamp, message));
          }
        }
      }

      // ナノ秒タイムスタンプ昇順でソート
      timedLines.sort((a, b) => a.key.compareTo(b.key));

      return timedLines.map((e) => e.value).toList();
    } catch (e, s) {
      stderr.writeln(
        '[LokiService] Error querying Loki for runId $runId: $e\n$s',
      );
      return [];
    }
  }

  /// Loki から指定した runId のステップイベント (type="step_event") を取得し、最新状態のステップリストを組み立てます
  Future<List<Map<String, dynamic>>> getStepSummariesForRun({
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

    final uri = Uri.parse('$lokiUrl/loki/api/v1/query_range').replace(
      queryParameters: {
        'query': querySelector,
        'limit': '1000',
        'direction': 'FORWARD',
        'start': sevenDaysAgoNano.toString(),
      },
    );

    try {
      stderr.writeln('[LokiService] Querying Loki URL: $uri');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      stderr.writeln(
        '[LokiService] Loki response status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode != 200) {
        stderr.writeln(
          '[LokiService] Loki step query failed with status ${response.statusCode}: ${response.body}',
        );
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String?;
      if (status != 'success') return [];

      final data = json['data'] as Map<String, dynamic>?;
      final result = data?['result'] as List<dynamic>?;
      if (result == null || result.isEmpty) return [];

      final Map<String, Map<String, dynamic>> stepsById = {};

      for (final streamItem in result) {
        if (streamItem is! Map<String, dynamic>) continue;
        final values = streamItem['values'] as List<dynamic>?;
        if (values == null) continue;

        for (final entry in values) {
          if (entry is List && entry.length >= 2) {
            final rawJson = entry[1].toString();
            try {
              final stepData = jsonDecode(rawJson) as Map<String, dynamic>;
              final id = stepData['id'] as String?;
              if (id != null && id.isNotEmpty) {
                // Normalize status if needed (e.g. RUNNING -> IN_PROGRESS)
                final rawStatus = stepData['status']?.toString().toUpperCase();
                if (rawStatus == 'RUNNING') {
                  stepData['status'] = 'IN_PROGRESS';
                }
                // 最新のステータス情報で上書き更新
                stepsById[id] = stepData;
              }
            } catch (_) {}
          }
        }
      }

      final stepList = stepsById.values.toList();
      stepList.sort((a, b) {
        final orderA = (a['stepOrder'] as num?)?.toInt() ?? 0;
        final orderB = (b['stepOrder'] as num?)?.toInt() ?? 0;
        return orderA.compareTo(orderB);
      });

      return stepList;
    } catch (e, s) {
      stderr.writeln(
        '[LokiService] Error querying step summaries for runId $runId: $e\n$s',
      );
      return [];
    }
  }

  /// Loki Tail API (WebSocket) から受信したフレームメッセージをパースし、
  /// (streamLabels, logLines) のリストを返します。
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
