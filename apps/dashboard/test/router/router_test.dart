import 'dart:async';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/router/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StreamController<User?> changes;
  late ProviderContainer container;
  late GoRouter router;

  void createRouter() {
    changes = StreamController<User?>.broadcast();
    addTearDown(changes.close);
    container = ProviderContainer.test(
      overrides: [
        firebaseAuthProvider.overrideWith((ref) async => _Auth()),
        authStateChangesProvider.overrideWith((ref) => changes.stream),
      ],
    );
    router = container.listen(routerProvider, (_, _) {}).read();
    addTearDown(router.dispose);
  }

  Future<Uri> resolve(WidgetTester tester, String location) async {
    final config = router.configuration;
    final matches = await config.redirect(
      tester.element(find.byType(SizedBox)),
      config.findMatch(Uri.parse(location)),
      redirectHistory: [],
    );
    expectSync(matches.error, isNull);
    return matches.uri;
  }

  test('auth events refresh the existing router', () async {
    createRouter();
    changes.add(null);
    await container.read(authStateChangesProvider.future);
    var refreshes = 0;
    router.routeInformationProvider.addListener(() {
      refreshes++;
    });

    for (final user in <User?>[_User(), null]) {
      final previous = refreshes;
      changes.add(user);
      await Future<void>.delayed(Duration.zero);

      expect(refreshes, previous + 1);
      expect(container.read(routerProvider), same(router));
    }
  });

  testWidgets(
    'redirects immediately when the sign-in event refreshes the router',
    (
      tester,
    ) async {
      createRouter();
      await tester.pumpWidget(const SizedBox());
      changes.add(null);
      await tester.pump();

      final context = tester.element(find.byType(SizedBox));
      final redirected = Completer<Uri>();
      router.routeInformationProvider.addListener(() async {
        final matches = await router.configuration.redirect(
          context,
          router.configuration.findMatch(Uri.parse('/auth')),
          redirectHistory: [],
        );
        redirected.complete(matches.uri);
      });

      changes.add(_User());
      await tester.pump();

      expect(await redirected.future, Uri.parse('/'));
    },
  );

  testWidgets('waits for authentication before resolving a protected URL', (
    tester,
  ) async {
    createRouter();
    await tester.pumpWidget(const SizedBox());
    const location = '/runs/job-123?tab=logs#step-2';
    var completed = false;
    final result = resolve(tester, location).then((uri) {
      completed = true;
      return uri;
    });

    await tester.pump();
    expect(completed, isFalse);

    changes.add(_User());
    await tester.pump();
    expect(await result, Uri.parse(location));
  });

  testWidgets('preserves the requested URL through sign-in and sign-out', (
    tester,
  ) async {
    createRouter();
    await tester.pumpWidget(const SizedBox());
    const location = '/runs/job-123?tab=logs#step-2';
    final result = resolve(tester, location);
    changes.add(null);
    await tester.pump();

    final authUri = await result;
    expect(authUri.path, '/auth');
    expect(authUri.queryParameters['from'], location);
    expect(await resolve(tester, authUri.toString()), authUri);

    changes.add(_User());
    await tester.pump();
    expect(await resolve(tester, authUri.toString()), Uri.parse(location));
    expect(await resolve(tester, '/auth'), Uri.parse('/'));

    changes.add(null);
    await tester.pump();
    expect(await resolve(tester, location), authUri);
  });
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class _User extends Fake implements User {}
