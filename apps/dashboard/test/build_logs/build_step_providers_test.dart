import 'dart:async';

import 'package:dashboard/build_logs/log_reader.dart';
import 'package:dashboard/cicd_log/detail/build_step_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'derived providers follow every snapshot and keep identical final lines',
    () async {
      final source = StreamController<RunLogs>();
      final run = buildRunLogsProvider(buildJobId: 'job', runId: 'run');
      final container = ProviderContainer.test(
        overrides: [run.overrideWith((ref) => source.stream)],
      );
      final step = buildStepLogDetailProvider(
        buildJobId: 'job',
        runId: 'run',
        stepId: 'build',
      );
      final all = allBuildStepLogsProvider(buildJobId: 'job', runId: 'run');
      container.listen(step, (_, _) {});
      container.listen(all, (_, _) {});
      await container.pump();
      source.add(
        RunLogs(
          LogState(lastSequence: BigInt.one, completed: false, steps: []),
          [LogEntry(BigInt.one, 'build', 'same\n')],
        ),
      );
      await container.pump();
      expect(await container.read(step.future), ['same\n']);
      source.add(
        RunLogs(
          LogState(lastSequence: BigInt.two, completed: true, steps: []),
          [
            LogEntry(BigInt.one, 'build', 'same\n'),
            LogEntry(BigInt.two, 'build', 'same\n'),
          ],
        ),
      );
      await container.pump();
      expect(await container.read(step.future), ['same\n', 'same\n']);
      expect(await container.read(all.future), 'same\nsame\n');
      unawaited(source.close());
      await container.pump();
    },
  );
}
