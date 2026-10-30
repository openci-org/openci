import 'dart:async';
import 'package:dashboard/build_logs/log_reader.dart';
import 'package:flutter_test/flutter_test.dart';

LogState state(int sequence, {bool done = false, bool expired = false}) =>
    LogState(
      lastSequence: BigInt.from(sequence),
      completed: done,
      steps: [],
      expired: expired,
    );

void main() {
  test(
    'drains pages and preserves repeated lines including final output',
    () async {
      final cursors = <BigInt>[];
      final results = await readRunLogs(
        states: Stream.value(state(451, done: true)),
        fetch: (after) async {
          cursors.add(after);
          final end = (after.toInt() + 200).clamp(0, 451);
          return [
            for (var i = after.toInt() + 1; i <= end; i++)
              LogEntry(BigInt.from(i), 'build', 'same\n'),
          ];
        },
      ).toList();
      expect(results.last.entries, hasLength(451));
      expect(cursors, [BigInt.zero, BigInt.from(200), BigInt.from(400)]);
    },
  );
  test('coalesces notifications during an in-flight page', () async {
    final events = StreamController<LogState>();
    final ready = Completer<void>();
    final started = Completer<void>();
    final results = readRunLogs(
      states: events.stream,
      fetch: (after) async {
        if (!started.isCompleted) started.complete();
        await ready.future;
        return [LogEntry(after + BigInt.one, 'build', 'line\n')];
      },
    ).toList();
    events.add(state(1));
    await started.future;
    events.add(state(2, done: true));
    ready.complete();
    expect((await results).last.entries.map((e) => e.sequence), [
      BigInt.one,
      BigInt.two,
    ]);
    await events.close();
  });
  test('expired logs do not fetch bodies', () async {
    final results = await readRunLogs(
      states: Stream.value(state(42, expired: true)),
      fetch: (_) async {
        fail('Expired log bodies must not be loaded');
      },
    ).toList();
    expect(results.single.entries, isEmpty);
  });
  test('retries final page without another notification', () async {
    final done = Completer<void>();
    var attempts = 0;
    final snapshots = <RunLogs>[];
    final errors = <Object>[];
    readRunLogs(
      states: Stream.value(state(1, done: true)),
      fetch: (_) async {
        if (++attempts == 1) throw StateError('offline');
        return [LogEntry(BigInt.one, 'build', 'final\n')];
      },
    ).listen(snapshots.add, onError: errors.add, onDone: done.complete);
    await done.future.timeout(const Duration(seconds: 5));
    expect(errors, hasLength(1));
    expect(snapshots.single.entries.single.message, 'final\n');
  });
}
