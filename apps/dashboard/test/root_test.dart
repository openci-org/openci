import 'dart:async';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/deep_link/deep_link_listener.dart';
import 'package:dashboard/root.dart';
import 'package:dashboard/router/router.dart';
import 'package:dashboard/utilities/sentry_provider_observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late StreamController<User?> changes;
  late ProviderContainer container;
  late GoRouter router;
  late int subscriptions;

  Future<void> pumpRoot(
    WidgetTester tester, {
    String location = '/runs/job-123?tab=logs#step-2',
  }) async {
    changes = StreamController<User?>.broadcast();
    addTearDown(changes.close);
    subscriptions = 0;
    router = GoRouter(
      initialLocation: location,
      routes: [
        for (final path in ['/auth', '/runs/:buildJobId'])
          GoRoute(
            path: path,
            builder: (_, _) => const Scaffold(body: Text('Routed page')),
          ),
      ],
    );
    addTearDown(router.dispose);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      observers: [SentryProviderObserver()],
      overrides: [
        authStateChangesProvider.overrideWith((ref) {
          subscriptions++;
          return changes.stream;
        }),
        deepLinkListenerProvider.overrideWith((ref) {}),
        routerProvider.overrideWithValue(router),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const Root()),
    );
  }

  for (final (user, location) in <(User?, String)>[
    (null, '/auth'),
    (_User(), '/runs/job-123'),
  ]) {
    testWidgets('shows loading until authentication resolves on $location', (
      tester,
    ) async {
      await pumpRoot(tester, location: location);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Routed page'), findsNothing);

      changes.add(user);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Routed page'), findsOneWidget);
      expect(router.state.uri.toString(), location);
    });
  }

  testWidgets('shows an error and retries authentication on the same route', (
    tester,
  ) async {
    await pumpRoot(tester);
    changes.add(_User());
    await tester.pumpAndSettle();
    final location = router.state.uri;

    changes.addError(StateError('Authentication failed'));
    await tester.pumpAndSettle();
    expect(find.text('認証状態を確認できませんでした。'), findsOneWidget);
    expect(find.text('Routed page'), findsNothing);

    await tester.tap(find.text('再試行'));
    await tester.pump();
    expect(subscriptions, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('再試行'), findsNothing);

    changes.add(_User());
    await tester.pumpAndSettle();
    expect(find.text('Routed page'), findsOneWidget);
    expect(router.state.uri, location);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the previous page while authentication refreshes', (
    tester,
  ) async {
    await pumpRoot(tester);
    changes.add(_User());
    await tester.pumpAndSettle();
    expect(find.text('Routed page'), findsOneWidget);

    expect(
      container.refresh(authStateChangesProvider).isLoading,
      isTrue,
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Routed page'), findsNothing);

    changes.add(_User());
    await tester.pumpAndSettle();
    expect(find.text('Routed page'), findsOneWidget);
  });
}

class _User extends Fake implements User {}
