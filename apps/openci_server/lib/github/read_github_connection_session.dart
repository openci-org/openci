import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_session_table.dart';

Future<DriftGitHubConnectionSession?> readGitHubConnectionSession({
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

    return await (db.select(db.gitHubConnectionSessions)..where(
          (session) =>
              session.referenceHash.equals(referenceHash) &
              session.userId.equals(userId) &
              session.teamId.equals(teamId) &
              session.expiresAt.isBiggerThanValue(currentTime) &
              session.consumedAt.isNull() &
              session.encryptedAccessToken.isNotNull() &
              existsQuery(membership),
        ))
        .getSingleOrNull();
  } catch (_) {
    // Database errors can include query values or stored credentials.
    throw StateError('Failed to read GitHub connection session');
  }
}
