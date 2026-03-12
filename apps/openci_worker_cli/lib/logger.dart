import 'package:dart_firebase_admin/firestore.dart';

enum LogLevel { info, warning, error }

Future<void> writeLogsToFirestore(
  Firestore firestore,
  String buildJobId,
  String runId,
  String message,
  LogLevel level, {
  String? stackTrace,
}) async {
  try {
    final logRef = firestore
        .collection('build_jobs_v0')
        .doc(buildJobId)
        .collection('runs')
        .doc(runId)
        .collection('logs')
        .doc();

    await logRef.set({
      'message': message,
      'level': level.name,
      'timestamp': FieldValue.serverTimestamp,
      'stackTrace': ?stackTrace,
    });
  } catch (e) {
    print('[Logger] Failed to write log to Firestore: $e');
  }
}

Future<void> logInfo(
  Firestore firestore,
  String buildJobId,
  String runId,
  String message,
) async {
  print('[INFO] $message');
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
  print('[WARNING] $message');
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
  print('[ERROR] $message');
  if (stackTrace != null) {
    print('[ERROR] Stack trace: $stackTrace');
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
