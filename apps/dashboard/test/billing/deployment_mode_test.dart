import 'package:dashboard/billing/billing_identity.dart';
import 'package:dashboard/billing/billing_provider.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/deployment_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('self-hosted web builds do not initialize billing dependencies', () {
    final container = ProviderContainer.test(
      overrides: [
        connectionStoreProvider.overrideWith((ref) {
          throw StateError('Billing must not initialize the connection store');
        }),
      ],
    );
    expect(
      container.read(billingWebSupportedProvider),
      kIsWeb && !selfHostedDeployment,
    );
    if (selfHostedDeployment || !kIsWeb) {
      expect(container.read(billingIdentityProvider), isNull);
      expect(
        container.read(billingStatusProvider('team')).asData?.value,
        isNull,
      );
    }
  });
}
