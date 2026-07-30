import 'package:logging/logging.dart';
import 'package:openci_build_job_processor/src/build_job_poller/wait_for_available_slot.dart';
import 'package:test/test.dart';

void main() {
  final testLogger = Logger('TestLogger');

  group('waitForAvailableSlot tests', () {
    test(
      'should finish immediately without waiting when a slot is already available',
      () async {
        int activeCount = 1;
        const maxConcurrent = 3;

        final stopwatch = Stopwatch()..start();
        await waitForAvailableSlot(
          delay: const Duration(milliseconds: 100),
          getActiveJobsCount: () => activeCount,
          maxConcurrentJobs: maxConcurrent,
          log: testLogger,
        );
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      },
    );

    test(
      'should wait when full and complete when a slot becomes available',
      () async {
        int activeCount = 3;
        const maxConcurrent = 3;

        Future.delayed(const Duration(milliseconds: 50), () {
          activeCount = 2;
        });

        final stopwatch = Stopwatch()..start();
        await waitForAvailableSlot(
          delay: const Duration(milliseconds: 20),
          getActiveJobsCount: () => activeCount,
          maxConcurrentJobs: maxConcurrent,
          log: testLogger,
        );
        stopwatch.stop();

        expect(activeCount, equals(2));
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
      },
    );
  });
}
