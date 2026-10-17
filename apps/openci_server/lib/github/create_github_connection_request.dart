import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/generate_random_value.dart';
import 'package:uuid/uuid.dart';

part 'create_github_connection_request.freezed.dart';

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

@Freezed(toStringOverride: false)
abstract class CreateGitHubConnectionRequestResult
    with _$CreateGitHubConnectionRequestResult {
  const factory CreateGitHubConnectionRequestResult({
    required String id,
    required String state,
    required String codeChallenge,
    required DateTime expiresAt,
  }) = _CreateGitHubConnectionRequestResult;
}
