@TestOn('vm')
library;

import 'package:dashboard/auth/google_sign_in.dart';
import 'package:dashboard/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native signup reuses the app OAuth client across connections',
    () async {
      final previousPlatform = GoogleSignInPlatform.instance;
      final google = _GooglePlatform();
      GoogleSignInPlatform.instance = google;
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() {
        GoogleSignInPlatform.instance = previousPlatform;
        debugDefaultTargetPlatformOverride = null;
      });

      final cloud = _Auth();
      final selfHosted = _Auth();
      expect(await GoogleSignInService().signIn(cloud), same(cloud.result));
      expect(
        await GoogleSignInService().signIn(selfHosted),
        same(selfHosted.result),
      );

      expect(google.initializations, hasLength(1));
      expect(
        google.initializations.single.clientId,
        DefaultFirebaseOptions.macos.iosClientId,
      );
      expect(cloud.credentials.single.providerId, 'google.com');
      expect(cloud.credentials.single.idToken, 'google-id-token-1');
      expect(selfHosted.credentials.single.providerId, 'google.com');
      expect(selfHosted.credentials.single.idToken, 'google-id-token-2');
    },
  );
}

class _GooglePlatform extends GoogleSignInPlatform {
  final initializations = <InitParameters>[];
  int authentications = 0;

  @override
  Future<void> init(InitParameters params) async {
    initializations.add(params);
  }

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    authentications++;
    return AuthenticationResults(
      user: const GoogleSignInUserData(
        id: 'google-user',
        email: 'user@example.com',
      ),
      authenticationTokens: AuthenticationTokenData(
        idToken: 'google-id-token-$authentications',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth extends Fake implements FirebaseAuth {
  final result = _Credential();
  final credentials = <OAuthCredential>[];

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    credentials.add(credential as OAuthCredential);
    return result;
  }
}

class _Credential extends Fake implements UserCredential {}
