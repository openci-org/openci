import 'dart:async';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('current user follows sign-in and sign-out', () async {
    final auth = _Auth();
    addTearDown(auth.changes.close);
    final container = ProviderContainer.test(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );
    container.listen(currentUserIdProvider, (_, _) {});
    container.listen(authStateChangesProvider, (_, _) {});
    await container.read(authStateChangesProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currentUserProvider), isNull);

    final user = _User();
    auth.setUser(user);
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    expect(container.read(currentUserProvider), same(user));
    expect(container.read(currentUserIdProvider), user.uid);

    auth.setUser(null);
    await Future<void>.delayed(Duration.zero);
    await container.pump();
    expect(container.read(currentUserProvider), isNull);
    expect(container.read(currentUserIdProvider), isNull);
  });
}

class _User extends Fake implements User {
  @override
  String get uid => 'user-1';
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? currentUser;

  final changes = StreamController<User?>.broadcast();

  @override
  Stream<User?> authStateChanges() async* {
    yield currentUser;
    yield* changes.stream;
  }

  void setUser(User? user) {
    currentUser = user;
    changes.add(user);
  }
}
