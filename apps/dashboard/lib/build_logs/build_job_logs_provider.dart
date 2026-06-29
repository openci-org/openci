import 'dart:async';
import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_job_logs_provider.freezed.dart';
part 'build_job_logs_provider.g.dart';

@freezed
abstract class BuildLog with _$BuildLog {
  const factory BuildLog({
    required String message,
    required String level,
    @DateTimeConverter() DateTime? timestamp,
  }) = _BuildLog;

  factory BuildLog.fromJson(Map<String, Object?> json) =>
      _$BuildLogFromJson(json);
}

@riverpod
Stream<List<BuildLog>> buildJobLogs(
  Ref ref,
  String buildJobId,
  String runId,
) async* {
  final serverUrl = ref.watch(openciServerUrlProvider);
  final url = Uri.parse('$serverUrl/builds/$buildJobId/runs/$runId/stream');
  final token = await ref.watch(authedFirebaseIdTokenProvider.future);

  final client = http.Client();
  final request = http.Request('GET', url);
  request.headers['Authorization'] = 'Bearer $token';
  request.headers['Accept'] = 'text/event-stream';
  request.headers['Cache-Control'] = 'no-cache';

  var isDisposed = false;
  ref.onDispose(() {
    isDisposed = true;
    client.close();
  });

  try {
    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to connect to log stream: ${response.statusCode}',
      );
    }

    final accumulatedLogs = <BuildLog>[];
    yield const [];

    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.startsWith('data:')) {
        final message = line.substring(5).trim();
        accumulatedLogs.add(
          BuildLog(
            message: message,
            level: 'info',
            timestamp: DateTime.now(),
          ),
        );
        yield List<BuildLog>.from(accumulatedLogs);
      }
    }
  } catch (e) {
    if (isDisposed) {
      return;
    }
    rethrow;
  }
}
