import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/generate_random_value.dart';
import 'package:uuid/uuid.dart';

Future<CreateGitHubConnectionRequestResult> createGitHubConnectionRequest({
  required AppDatabase db,
  required String userId,
  required String teamId,
  @visibleForTesting DateTime? now,
}) async {
  final state = generateRandomValue();
  final codeVerifier = generateRandomValue();
  final createdAt = (now ?? DateTime.now()).toUtc();
  final request = DriftGitHubConnectionRequest(
    id: const Uuid().v4(),
    userId: userId,
    teamId: teamId,
    stateHash: sha256.convert(utf8.encode(state)).toString(),
    codeVerifier: codeVerifier,
    createdAt: createdAt,
    expiresAt: createdAt.add(const Duration(minutes: 10)),
  );

  await db.into(db.gitHubConnectionRequests).insert(request);

  return CreateGitHubConnectionRequestResult(
    id: request.id,
    state: state,
    codeChallenge: base64UrlEncode(
      sha256.convert(ascii.encode(codeVerifier)).bytes,
    ).replaceAll('=', ''),
    expiresAt: request.expiresAt,
  );
}

class CreateGitHubConnectionRequestResult {
  const CreateGitHubConnectionRequestResult({
    required this.id,
    required this.state,
    required this.codeChallenge,
    required this.expiresAt,
  });

  final String id;
  final String state;
  final String codeChallenge;
  final DateTime expiresAt;
}
