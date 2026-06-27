import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
Future<String?> firebaseIdToken(Ref ref) async =>
    ref.watch(firebaseAuthProvider).currentUser?.getIdToken();

@riverpod
Future<String> authedFirebaseIdToken(Ref ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    throw StateError('User is not authenticated');
  }
  final token = await user.getIdToken(true);
  if (token == null) {
    throw StateError('Could not get Firebase ID token');
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
