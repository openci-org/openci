import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/log_reader.dart';
import 'package:dashboard/build_logs/logs_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_step_providers.g.dart';

Future<RunLogs> _snapshot(Ref ref, String buildJobId, String runId) async {
  final provider = buildRunLogsProvider(buildJobId: buildJobId, runId: runId);
  // A StreamProvider's .future resolves only its first value. Watch AsyncValue
  // as well so every subsequent log notification rebuilds these projections.
  final state = ref.watch(provider);
  if (state.hasError) {
    Error.throwWithStackTrace(state.error!, state.stackTrace!);
  }
  if (state.hasValue) return state.requireValue;
  return ref.watch(provider.future);
}

@riverpod
Stream<RunLogs> buildRunLogs(
  Ref ref, {
  required String buildJobId,
  required String runId,
}) async* {
  if (runId.isEmpty) return;
  final job = await ref.watch(buildJobByIdProvider(buildJobId).future);
  if (job?.teamId == null) throw StateError('Build team not found');
  final repository = await ref.watch(logsRepositoryProvider.future);
  yield* repository.watch(job!.teamId!, buildJobId, runId);
}

@riverpod
Future<List<BuildStep>> buildStepSummaries(
  Ref ref, {
  required String buildJobId,
  required String runId,
}) async {
  if (runId.isEmpty) return [];
  return (await _snapshot(ref, buildJobId, runId)).state.steps;
}

@riverpod
Future<List<String>> buildStepLogDetail(
  Ref ref, {
  required String buildJobId,
  required String runId,
  required String stepId,
}) async {
  if (runId.isEmpty) return [];
  final logs = await _snapshot(ref, buildJobId, runId);
  return logs.entries
      .where((entry) => entry.stepId == stepId)
      .map((entry) => entry.message)
      .toList();
}

@riverpod
Future<String> allBuildStepLogs(
  Ref ref, {
  required String buildJobId,
  required String runId,
}) async {
  if (runId.isEmpty) return '';
  final logs = await _snapshot(ref, buildJobId, runId);
  return logs.entries.map((entry) => entry.message).join();
}
