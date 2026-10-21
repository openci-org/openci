@TestOn('browser')
library;

import 'package:dashboard/billing/billing_identity.dart';
import 'package:dashboard/billing/billing_page.dart';
import 'package:dashboard/billing/billing_provider.dart';
import 'package:dashboard/billing/billing_status.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

void main() {
  testWidgets(
    'restoring a cached page refreshes once and detaches on disposal',
    (
      tester,
    ) async {
      var reads = 0;
      final container = ProviderContainer.test(
        overrides: [
          billingIdentityProvider.overrideWith(
            (ref) => (
              connection: const ConnectionProfile(
                id: 'cloud',
                name: 'Cloud',
                apiUrl: 'https://api.example.com',
                firebase: {},
              ),
              userId: 'user-1',
            ),
          ),
          teamListProvider.overrideWith(
            (ref) async => [
              Team(
                id: 'team-1',
                name: 'Team',
                members: const ['user-1'],
                createdAt: DateTime.utc(2026),
                updatedAt: DateTime.utc(2026),
              ),
            ],
          ),
          billingStatusProvider('team-1').overrideWith((ref) async {
            reads++;
            return BillingStatus.fromJson({
              'billingEnabled': true,
              'planId': null,
              'canStartCi': false,
              'blockReason': 'payment_required',
              'paidUntil': null,
              'canCheckout': true,
              'canManageBilling': false,
              'cancelAtPeriodEnd': false,
            });
          }),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BillingPage(teamId: 'team-1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(reads, 1);
      web.window.dispatchEvent(
        web.PageTransitionEvent(
          'pageshow',
          web.PageTransitionEventInit(persisted: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(reads, 1);
      web.window.dispatchEvent(
        web.PageTransitionEvent(
          'pageshow',
          web.PageTransitionEventInit(persisted: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(reads, 2);
      await tester.pump(const Duration(minutes: 5));
      expect(reads, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      web.window.dispatchEvent(
        web.PageTransitionEvent(
          'pageshow',
          web.PageTransitionEventInit(persisted: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
