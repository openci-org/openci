import 'package:http/http.dart' as http;

import '../auth/firebase_auth_client.dart';
import 'credential_config.dart';
import 'credential_store.dart';

Future<AuthProfile?> readAuthenticatedProfile(CredentialStore store) async {
  final config = await store.get();
  final profile = config.profiles[config.activeProfile];
  if (profile == null || profile.authType != 'firebase') return profile;

  final expiresAt = profile.expiresAt;
  if (profile.token.isNotEmpty &&
      expiresAt != null &&
      expiresAt.isAfter(
        DateTime.now().toUtc().add(const Duration(minutes: 1)),
      )) {
    return profile;
  }
  if (profile.firebaseApiKey.isEmpty || profile.refreshToken.isEmpty) {
    throw const FirebaseAuthException();
  }

  final client = http.Client();
  try {
    final session = await FirebaseAuthClient(client).refresh(
      apiKey: profile.firebaseApiKey,
      refreshToken: profile.refreshToken,
    );
    final updated = profile.copyWith(
      token: session.token,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
    await store.saveProfile(config.activeProfile, updated, setActive: false);
    return updated;
  } finally {
    client.close();
  }
}
