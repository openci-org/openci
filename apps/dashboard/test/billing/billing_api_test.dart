import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/billing/billing_api.dart';
import 'package:dashboard/billing/billing_response.dart';
import 'package:flutter_test/flutter_test.dart';

class _Callable extends Fake implements HttpsCallable {
  final calls = <dynamic>[];
  Future<Map<String, dynamic>> Function() respond = () async => {
    'success': true,
  };
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    calls.add(parameters);
    return _Result<T>((await respond()) as T);
  }
}

class _Result<T> extends Fake implements HttpsCallableResult<T> {
  _Result(this.data);
  @override
  final T data;
}

void main() {
  late _Callable callable;
  late BillingApi api;
  var current = true;
  setUp(() {
    current = true;
    callable = _Callable();
    api = BillingApi(callable: callable, isCurrent: () => current);
  });
  Matcher reason(String value) =>
      isA<BillingException>().having((e) => e.code, 'code', value);

  test('sends only callable inputs and requires confirmed deletion', () async {
    await api.call('checkout', 'team', planId: 'light');
    await api.deleteTeam('team');
    expect(callable.calls, [
      {'action': 'checkout', 'teamId': 'team', 'planId': 'light'},
      {'action': 'deleteTeam', 'teamId': 'team'},
    ]);
    callable.respond = () async => {};
    await expectLater(
      api.deleteTeam('team'),
      throwsA(reason('billing_unavailable')),
    );
  });

  test(
    'blocks stale calls and discards results after authentication changes',
    () async {
      current = false;
      await expectLater(
        api.call('status', 'team'),
        throwsA(reason('context_changed')),
      );
      expect(callable.calls, isEmpty);
      current = true;
      final pending = Completer<Map<String, dynamic>>();
      callable.respond = () => pending.future;
      final result = api.call('portal', 'team');
      current = false;
      pending.complete({'url': 'https://billing.stripe.com/p/session/private'});
      await expectLater(result, throwsA(reason('context_changed')));
    },
  );

  test(
    'exposes only known billing reasons, never Stripe or SDK error text',
    () async {
      for (final (code, details, expected) in [
        ('unauthenticated', null, 'authentication_required'),
        ('permission-denied', null, 'forbidden'),
        (
          'failed-precondition',
          {'reason': 'subscription_exists'},
          'subscription_exists',
        ),
        (
          'unavailable',
          {'reason': 'private purchase information'},
          'billing_unavailable',
        ),
        ('internal', 'private purchase information', 'billing_unavailable'),
      ]) {
        callable.respond = () => throw FirebaseFunctionsException(
          code: code,
          message: 'private token',
          details: details,
        );
        await expectLater(
          api.call('status', 'team'),
          throwsA(reason(expected)),
        );
      }
    },
  );
}
