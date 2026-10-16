import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:openci_server/database.dart';

Future<bool> consumeGitHubConnectionSession({
  required AppDatabase db,
  required String reference,
  required String userId,
  required String teamId,
  @visibleForTesting DateTime? now,
}) async {
  final referenceHash = sha256.convert(utf8.encode(reference)).toString();
  final currentTime = (now ?? DateTime.now()).toUtc();

  try {
    final membership = db.select(db.teamMembers)
      ..where(
        (member) => member.userId.equals(userId) & member.teamId.equals(teamId),
      );

    final updated =
        await (db.update(db.gitHubConnectionSessions)..where(
              (session) =>
                  session.referenceHash.equals(referenceHash) &
                  session.userId.equals(userId) &
                  session.teamId.equals(teamId) &
                  session.expiresAt.isBiggerThanValue(currentTime) &
                  session.consumedAt.isNull() &
                  session.encryptedAccessToken.isNotNull() &
                  existsQuery(membership),
            ))
            .write(
              GitHubConnectionSessionsCompanion(
                consumedAt: Value(currentTime),
                encryptedAccessToken: const Value(null),
              ),
            );

    return updated == 1;
  } catch (_) {
    // Database errors can include query values or stored credentials.
    throw StateError('Failed to consume GitHub connection session');
  }
}
