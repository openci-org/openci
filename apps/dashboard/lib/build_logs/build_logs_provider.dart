import 'package:dashboard/firebase/dataconnect.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logs_provider.freezed.dart';
part 'logs_provider.g.dart';

@riverpod
Stream<List<BuildLog>> buildLogs(
  Ref ref,
  String buildJobId,
  String runId,
) async* {
  final teamId = ref.watch(teamStateProvider).value?.id;
  if (teamId == null) {
    yield const [];
    return;
  }
  final query = dataConnector
      .listBuildLogsForRun(
        buildJobId: buildJobId,
        runId: runId,
        teamId: teamId,
      )
      .ref();

  final initial = await query.execute();
  yield _buildLogsFromResult(initial.data.buildLogs);

  yield* query.subscribe().map(
    (result) => _buildLogsFromResult(result.data.buildLogs),
  );
}

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

List<BuildLog> _buildLogsFromResult(List<ListBuildLogsForRunBuildLogs> logs) {
  return logs
      .map(
        (log) => BuildLog(
          message: log.message,
          level: log.level ?? 'info',
          timestamp: dateTimeFromDataConnect(log.timestamp),
        ),
      )
      .toList();
}
