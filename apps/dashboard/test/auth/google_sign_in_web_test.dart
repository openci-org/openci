@TestOn('browser')
library;

import 'package:dashboard/auth/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses the selected Firebase auth instance for the Google popup',
    () async {
      final auth = _Auth();
      final result = await GoogleSignInService().signIn(auth);
      expect(result, same(auth.credential));
      expect(auth.provider, isA<GoogleAuthProvider>());
      expect(
        (auth.provider! as GoogleAuthProvider).parameters['prompt'],
        'select_account',
      );
    },
  );

  for (final code in ['popup-closed-by-user', 'cancelled-popup-request']) {
    test('$code is a canceled login, not a failed signup', () async {
      final auth = _Auth(error: FirebaseAuthException(code: code));
      expect(await GoogleSignInService().signIn(auth), isNull);
    });
  }

  test(
    'preserves provider conflicts for the existing-login guidance',
    () async {
      final error = FirebaseAuthException(
        code: 'account-exists-with-different-credential',
      );
      await expectLater(
        GoogleSignInService().signIn(_Auth(error: error)),
        throwsA(same(error)),
      );
    },
  );
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth({this.error});
  final FirebaseAuthException? error;
  final credential = _Credential();
  AuthProvider? provider;

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async {
    this.provider = provider;
    if (error != null) throw error!;
    return credential;
  }
}

class _Credential extends Fake implements UserCredential {}
