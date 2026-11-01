import 'models.dart';

/// Stop starting work before Cloud Tasks can retry a timed-out invocation.
class Deadline {
  Deadline(Duration budget) : _budget = budget;
  final Duration _budget;
  final Stopwatch _watch = Stopwatch()..start();

  Duration limit(Duration maximum) {
    final remaining = _budget - _watch.elapsed;
    if (remaining <= Duration.zero) throw const RetryException('Execution deadline reached');
    return remaining < maximum ? remaining : maximum;
  }
}
