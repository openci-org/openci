import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:openci_server/database.dart';

Future<int> deleteExpiredGitHubConnectionSessions({
  required AppDatabase db,
  @visibleForTesting DateTime? now,
}) async {
  final currentTime = (now ?? DateTime.now()).toUtc();

  try {
    return await (db.delete(db.gitHubConnectionSessions)..where(
          (session) => session.expiresAt.isSmallerOrEqualValue(currentTime),
        ))
        .go();
  } catch (_) {
    // Database errors can include query values or stored credentials.
    throw StateError('Failed to delete expired GitHub connection sessions');
  }
}
