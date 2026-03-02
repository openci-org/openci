import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  Stream<User?> build() {
    return FirebaseAuth.instance.authStateChanges();
  }

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
}
