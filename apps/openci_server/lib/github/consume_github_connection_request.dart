import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:openci_server/database.dart';

Future<DriftGitHubConnectionRequest?> consumeGitHubConnectionRequest({
  required AppDatabase db,
  required String state,
  @visibleForTesting DateTime? now,
}) async {
  final stateHash = sha256.convert(utf8.encode(state)).toString();
  final currentTime = (now ?? DateTime.now()).toUtc();

  // Delete and return in one statement so only one caller can consume it.
  final requests =
      await (db.delete(db.gitHubConnectionRequests)..where(
            (request) =>
                request.stateHash.equals(stateHash) &
                request.expiresAt.isBiggerThanValue(currentTime),
          ))
          .goAndReturn();

  return requests.singleOrNull;
}
