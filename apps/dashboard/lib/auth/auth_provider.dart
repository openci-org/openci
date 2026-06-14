import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
Stream<User?> authStateChanges(Ref ref) =>
    ref.watch(firebaseAuthProvider).authStateChanges();

@riverpod
String? currentUserEmail(Ref ref) =>
    ref.watch(authStateChangesProvider).value?.email;

@riverpod
String? currentUserId(Ref ref) =>
    ref.watch(authStateChangesProvider).value?.uid;

@riverpod
String nonNullCurrentUserId(Ref ref) {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) {
    throw StateError('User is not authenticated');
  }
  return id;
}
