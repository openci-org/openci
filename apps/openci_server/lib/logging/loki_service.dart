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
        ? '{run_id="$runId", step_id="$stepId"}'
        : '{run_id="$runId"}';

    final uri = Uri.parse('$lokiUrl/loki/api/v1/query_range').replace(
      queryParameters: {
        'query': querySelector,
        'limit': limit.toString(),
        'direction': 'FORWARD',
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
}
