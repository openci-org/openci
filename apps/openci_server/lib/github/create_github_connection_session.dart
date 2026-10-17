import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/generate_random_value.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:uuid/uuid.dart';

part 'create_github_connection_session.freezed.dart';

Future<CreateGitHubConnectionSessionResult> createGitHubConnectionSession({
  required AppDatabase db,
  required SecretCrypter crypter,
  required String userId,
  required String teamId,
  required int githubUserId,
  required String accessToken,
  @visibleForTesting DateTime? now,
}) async {
  if (githubUserId <= 0) {
    throw ArgumentError('GitHub user ID must be positive');
  }
  if (accessToken.trim().isEmpty) {
    throw ArgumentError('GitHub access token is required');
  }

  try {
    final encryptedAccessToken = await crypter.encrypt(accessToken);
    final reference = generateRandomValue();
    final createdAt = (now ?? DateTime.now()).toUtc();
    final expiresAt = createdAt.add(const Duration(minutes: 10));

    await db
        .into(db.gitHubConnectionSessions)
        .insert(
          GitHubConnectionSessionsCompanion.insert(
            id: const Uuid().v4(),
            userId: userId,
            teamId: teamId,
            githubUserId: githubUserId,
            referenceHash: sha256.convert(utf8.encode(reference)).toString(),
            encryptedAccessToken: Value(encryptedAccessToken),
            createdAt: createdAt,
            expiresAt: expiresAt,
          ),
        );

    return CreateGitHubConnectionSessionResult(
      reference: reference,
      expiresAt: expiresAt,
    );
  } catch (_) {
    // Encryption and database errors can contain credentials or query values.
    throw StateError('Failed to create GitHub connection session');
  }
}

@Freezed(toStringOverride: false)
abstract class CreateGitHubConnectionSessionResult
    with _$CreateGitHubConnectionSessionResult {
  const factory CreateGitHubConnectionSessionResult({
    required String reference,
    required DateTime expiresAt,
  }) = _CreateGitHubConnectionSessionResult;
}
