import 'dart:async';

import 'package:dashboard/cicd_log/detail/build_step_mock_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../build_logs/build_step_providers.g.dart';

@riverpod
Future<List<BuildStepSummary>> buildStepSummaries(
  Ref ref,
  String buildJobId,
) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return mockBuildSteps;
}

@riverpod
Future<List<String>> buildStepLogDetail(Ref ref, String stepId) async {
  await Future.delayed(const Duration(seconds: 2));
  return mockStepLogs[stepId] ?? const ['No logs for this step.'];
}
