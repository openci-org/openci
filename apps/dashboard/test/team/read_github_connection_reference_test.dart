import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:dashboard/team/read_github_connection_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const context = GitHubConnectionContext(
    profileId: 'self-hosted',
    apiUrl: 'https://ci.example.test',
    userId: 'user-1',
    teamId: 'team-1',
  );
  const reference = 'private-reference';
  late GitHubConnectionReturn? result;
  late GitHubConnectionContext? initiatingContext;
  late GitHubConnectionContext? currentContext;

  setUp(() {
    result = parseGitHubConnectionReturn('reference=$reference');
    initiatingContext = context;
    currentContext = context.copyWith();
  });

  String readReference() => readGitHubConnectionReference(
    result: result,
    initiatingContext: initiatingContext,
    currentContext: currentContext,
  );

  test('returns the reference when the initiating context still matches', () {
    expect(readReference(), reference);
  });

  test('preserves cancellation even when the context is unavailable', () {
    result = parseGitHubConnectionReturn('error=access_denied');
    initiatingContext = null;
    currentContext = null;

    expect(readReference, throwsA(GitHubConnectionReturnError.accessDenied));
  });

  test('preserves a rejected callback error', () {
    result = parseGitHubConnectionReturn('error=invalid_state');

    expect(readReference, throwsA(GitHubConnectionReturnError.invalidState));
  });

  test('rejects a missing return', () {
    result = null;

    expect(readReference, throwsA(GitHubConnectionReturnError.invalidResult));
  });

  test('rejects a missing initiating context', () {
    initiatingContext = null;

    expect(readReference, throwsA(GitHubConnectionReturnError.forbidden));
  });

  test('rejects an unavailable current context', () {
    currentContext = null;

    expect(readReference, throwsA(GitHubConnectionReturnError.forbidden));
  });

  test('rejects a different signed-in user', () {
    currentContext = context.copyWith(userId: 'user-2');

    expect(readReference, throwsA(GitHubConnectionReturnError.forbidden));
  });

  test('rejects a different team', () {
    currentContext = context.copyWith(teamId: 'team-2');

    expect(readReference, throwsA(GitHubConnectionReturnError.forbidden));
  });

  test('rejects a different connection profile', () {
    currentContext = context.copyWith(profileId: 'another-profile');

    expect(readReference, throwsA(GitHubConnectionReturnError.forbidden));
  });

  test('rejects a changed server URL on the same profile', () {
    currentContext = context.copyWith(apiUrl: 'https://other.example.test');

    expect(readReference, throwsA(GitHubConnectionReturnError.forbidden));
  });
}
