import 'dart:async';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/router/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('auth events refresh the existing router', () async {
    final changes = StreamController<User?>.broadcast();
    addTearDown(changes.close);
    final container = ProviderContainer.test(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => changes.stream),
      ],
    );
    final router = container.listen(routerProvider, (_, _) {}).read();
    addTearDown(router.dispose);

    var refreshes = 0;
    router.routeInformationProvider.addListener(() {
      refreshes++;
    });

    for (final user in <User?>[null, _User(), null]) {
      final previous = refreshes;
      changes.add(user);
      await Future<void>.delayed(Duration.zero);

      expect(refreshes, previous + 1);
      expect(container.read(routerProvider), same(router));
    }
  });
}

class _User extends Fake implements User {}
