import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:dashboard/team/pending_github_connection_return_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delivers the captured reference only once', () {
    final result = parseGitHubConnectionReturn('reference=private-reference');
    final pending = PendingGitHubConnectionReturn(result);

    expect(pending.take(), same(result));
    expect(pending.take(), isNull);
  });

  test('delivers a captured error only once', () {
    final result = parseGitHubConnectionReturn('error=access_denied');
    final pending = PendingGitHubConnectionReturn(result);

    expect(pending.take()!.error, GitHubConnectionReturnError.accessDenied);
    expect(pending.take(), isNull);
  });

  test('the default provider has no pending return', () {
    final container = ProviderContainer.test();

    expect(
      container.read(pendingGitHubConnectionReturnProvider).take(),
      isNull,
    );
  });

  test('reading the provider again does not restore a consumed return', () {
    final result = parseGitHubConnectionReturn('reference=private-reference');
    final container = ProviderContainer.test(
      overrides: [
        pendingGitHubConnectionReturnProvider.overrideWithValue(
          PendingGitHubConnectionReturn(result),
        ),
      ],
    );

    expect(
      container.read(pendingGitHubConnectionReturnProvider).take(),
      result,
    );
    expect(
      container.read(pendingGitHubConnectionReturnProvider).take(),
      isNull,
    );
  });
}
