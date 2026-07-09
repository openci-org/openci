import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
Stream<String?> firebaseIdToken(Ref ref) {
  return ref.watch(firebaseAuthProvider).idTokenChanges().asyncMap((
    user,
  ) async {
    if (user == null) return null;
    return user.getIdToken();
  });
}

@riverpod
Future<String> authedFirebaseIdToken(Ref ref) async {
  final token = await ref.watch(firebaseIdTokenProvider.future);
  if (token == null) {
    throw StateError('User is not authenticated');
  }
  return token;
}

@riverpod
Stream<User?> authStateChanges(Ref ref) =>
    ref.watch(firebaseAuthProvider).authStateChanges();

@riverpod
User? currentUser(Ref ref) => ref.watch(firebaseAuthProvider).currentUser;

@riverpod
String? currentUserEmail(Ref ref) => ref.watch(currentUserProvider)?.email;

@riverpod
String? currentUserId(Ref ref) => ref.watch(currentUserProvider)?.uid;

@riverpod
String nonNullCurrentUserId(Ref ref) {
  final id = ref.watch(currentUserIdProvider);
  if (id == null) {
    throw StateError('User is not authenticated');
  }
  return id;
}
