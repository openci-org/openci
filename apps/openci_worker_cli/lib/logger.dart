import 'dart:async';

import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:openci_shared/firestore_paths.dart';

final _log = Logger('BuildLog');

enum LogLevel { info, warning, error }

const _maxConcurrent = 5;
int _activeWrites = 0;
final _writeQueue = <Future<void> Function()>[];

Future<void> _enqueue(Future<void> Function() task) async {
  if (_activeWrites >= _maxConcurrent) {
    final completer = Completer<void>();
    _writeQueue.add(() async {
      try {
        await task();
      } finally {
        completer.complete();
      }
    });
    return completer.future;
  }

  _activeWrites++;
  try {
    await task();
  } finally {
    _activeWrites--;
    _drainQueue();
  }
}

void _drainQueue() {
  while (_writeQueue.isNotEmpty && _activeWrites < _maxConcurrent) {
    final next = _writeQueue.removeAt(0);
    _activeWrites++;
    next().whenComplete(() {
      _activeWrites--;
      _drainQueue();
    });
  }
}

Future<void> flushRemainingLogs() async {
  while (_activeWrites > 0 || _writeQueue.isNotEmpty) {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

Future<void> writeLogsToFirestore(
  Firestore firestore,
  String buildJobId,
  String runId,
  String message,
  LogLevel level, {
  String? stackTrace,
}) async {
  await _enqueue(() async {
    try {
      final logRef = firestore
          .collection(buildJobsCollection)
          .doc(buildJobId)
          .collection('runs')
          .doc(runId)
          .collection('logs')
          .doc();
      await logRef.set({
        'message': message,
        'level': level.name,
        'timestamp': DateTime.now().toIso8601String(),
        'stackTrace': ?stackTrace,
      });
    } catch (e) {
      _log.warning('Failed to write log to Firestore: $e');
    }
  });
}

Future<void> logInfo(
  Firestore firestore,
  String buildJobId,
  String runId,
  String message,
) async {
  _log.info(message);
  await writeLogsToFirestore(
    firestore,
    buildJobId,
    runId,
    message,
    LogLevel.info,
  );
}

Future<void> logWarning(
  Firestore firestore,
  String buildJobId,
  String runId,
  String message,
) async {
  _log.warning(message);
  await writeLogsToFirestore(
    firestore,
    buildJobId,
    runId,
    message,
    LogLevel.warning,
  );
}

Future<void> logError(
  Firestore firestore,
  String buildJobId,
  String runId,
  String message, {
  String? stackTrace,
}) async {
  _log.severe(message);
  if (stackTrace != null) {
    _log.severe('Stack trace: $stackTrace');
  }
  await writeLogsToFirestore(
    firestore,
    buildJobId,
    runId,
    message,
    LogLevel.error,
    stackTrace: stackTrace,
  );
}
