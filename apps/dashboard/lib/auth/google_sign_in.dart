import 'package:dashboard/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleSignInProvider = Provider<GoogleSignInService>(
  (ref) => GoogleSignInService(),
);

class GoogleSignInService {
  static Future<void>? _initialization;

  Future<UserCredential?> signIn(FirebaseAuth auth) async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        return await auth.signInWithPopup(provider);
      }

      final google = GoogleSignIn.instance;
      // The native OAuth client belongs to this app build and its URL schemes.
      // Exchange the credential with the selected Firebase connection below.
      await (_initialization ??= google.initialize(
        clientId: DefaultFirebaseOptions.currentPlatform.iosClientId,
      ));
      final account = await google.authenticate();
      return await auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: account.authentication.idToken),
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw FirebaseAuthException(code: 'google-sign-in-failed');
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'cancelled-popup-request') {
        return null;
      }
      rethrow;
    }
  }
}
