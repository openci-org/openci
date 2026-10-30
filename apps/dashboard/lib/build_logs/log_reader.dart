import 'dart:async';

import 'package:openci_shared/openci_shared.dart';

class LogEntry {
  const LogEntry(this.sequence, this.stepId, this.message);
  final BigInt sequence;
  final String? stepId;
  final String message;
}

class LogState {
  const LogState({
    required this.lastSequence,
    required this.completed,
    required this.steps,
    this.expired = false,
  });
  final BigInt lastSequence;
  final bool completed;
  final List<BuildStep> steps;
  final bool expired;
}

class RunLogs {
  const RunLogs(this.state, this.entries);
  final LogState state;
  final List<LogEntry> entries;
}

// One subscription per run. Coalesce notifications while draining paginated
// output; never use message equality to discard legitimate repeated lines.
Stream<RunLogs> readRunLogs({
  required Stream<LogState> states,
  required Future<List<LogEntry>> Function(BigInt after) fetch,
}) {
  late StreamController<RunLogs> controller;
  StreamSubscription<LogState>? subscription;
  Timer? retry;
  LogState? latest;
  var cursor = BigInt.zero;
  final entries = <LogEntry>[];
  var busy = false;
  var stopped = false;

  Future<void> drain() async {
    if (busy || stopped || latest == null) return;
    busy = true;
    try {
      while (!stopped) {
        final state = latest!;
        if (state.expired) {
          entries.clear();
        } else {
          while (cursor < state.lastSequence && !stopped) {
            final page = await fetch(cursor);
            if (stopped) return;
            if (page.isEmpty) throw StateError('Log page is not available yet');
            final previous = cursor;
            for (final entry in page) {
              if (entry.sequence > cursor) {
                entries.add(entry);
                cursor = entry.sequence;
              }
            }
            if (cursor == previous) {
              throw StateError('Log cursor did not advance');
            }
          }
        }
        if (stopped) return;
        controller.add(RunLogs(state, List.unmodifiable(entries)));
        if (!identical(state, latest)) continue;
        if (state.completed || state.expired) {
          await subscription?.cancel();
          subscription = null;
          stopped = true;
          unawaited(controller.close());
        }
        break;
      }
    } catch (error, stack) {
      if (!stopped) {
        controller.addError(error, stack);
        // Fetch errors must be retried even when the completed run no longer
        // emits new invalidations. Keep the successful cursor and entries.
        retry?.cancel();
        retry = Timer(const Duration(seconds: 2), drain);
      }
    } finally {
      busy = false;
    }
  }

  controller = StreamController<RunLogs>(
    onListen: () {
      subscription = states.listen(
        (state) {
          latest = state;
          unawaited(drain());
        },
        onError: (Object error, StackTrace stack) {
          if (!stopped) controller.addError(error, stack);
        },
      );
    },
    onCancel: () async {
      stopped = true;
      retry?.cancel();
      await subscription?.cancel();
    },
  );
  return controller.stream;
}
