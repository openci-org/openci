import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  Stream<User?> build() => getFirebaseAuth().authStateChanges();

  FirebaseAuth getFirebaseAuth() {
    if (Firebase.apps.length == 1 && Firebase.apps.first.name == '[DEFAULT]') {
      return FirebaseAuth.instance;
    }
    final nonDefaultFirebaseApps = Firebase.apps.where(
      (app) => app.name != '[DEFAULT]',
    );
    return FirebaseAuth.instanceFor(app: nonDefaultFirebaseApps.first);
  }
}
