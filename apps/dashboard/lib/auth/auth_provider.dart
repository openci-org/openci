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
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) {
    throw Exception('User is not authenticated');
  }
  return user.uid;
}
