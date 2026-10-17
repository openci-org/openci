import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void expectError(String fragment, GitHubConnectionReturnError error) {
    final result = parseGitHubConnectionReturn(fragment);

    expect(result.reference, isNull);
    expect(result.error, error);
  }

  void expectInvalid(String fragment) =>
      expectError(fragment, GitHubConnectionReturnError.invalidResult);

  test('reads the opaque reference from a callback URI fragment', () {
    final uri = Uri.parse(
      'https://dashboard.example/github/connection#reference=private-reference',
    );

    final result = parseGitHubConnectionReturn(uri.fragment);

    expect(result.reference, 'private-reference');
    expect(result.error, isNull);
    expect(result.toString(), isNot(contains('private-reference')));
  });

  test('decodes a reference without treating its contents as fields', () {
    final result = parseGitHubConnectionReturn(
      'reference=opaque%2Bvalue%26error%3Daccess_denied',
    );

    expect(result.reference, 'opaque+value&error=access_denied');
    expect(result.error, isNull);
  });

  test('recognizes denied authorization', () {
    expectError(
      'error=access_denied',
      GitHubConnectionReturnError.accessDenied,
    );
  });

  test('recognizes invalid callback parameters', () {
    expectError(
      'error=invalid_callback',
      GitHubConnectionReturnError.invalidCallback,
    );
  });

  test('recognizes an invalid authorization state', () {
    expectError(
      'error=invalid_state',
      GitHubConnectionReturnError.invalidState,
    );
  });

  test('recognizes lost team membership', () {
    expectError('error=forbidden', GitHubConnectionReturnError.forbidden);
  });

  test('recognizes a failed connection attempt', () {
    expectError(
      'error=connection_failed',
      GitHubConnectionReturnError.connectionFailed,
    );
  });

  test('rejects a missing or empty reference', () {
    expectInvalid('');
    expectInvalid('reference');
    expectInvalid('reference=');
    expectInvalid('reference=%20%09');
  });

  test('rejects multiple reference values', () {
    expectInvalid('reference=first&reference=second');
  });

  test('rejects multiple error values', () {
    expectInvalid('error=access_denied&error=forbidden');
  });

  test('rejects a reference mixed with an error', () {
    expectInvalid('reference=private-reference&error=access_denied');
  });

  test('rejects extra fields instead of trusting caller metadata', () {
    expectInvalid('reference=private-reference&teamId=forged-team');
    expectInvalid('error=access_denied&error_description=private-detail');
  });

  test('does not treat a success flag as proof of a connection', () {
    expectInvalid('success=true');
  });

  test('rejects missing or unknown error codes', () {
    expectInvalid('error=');
    expectInvalid('error=private-upstream-error');
  });

  test('rejects malformed encoding without throwing input details', () {
    expectInvalid('reference=private-reference%');
    expectInvalid('reference=%GG');
    expectInvalid('error=%FF');
  });

  test('does not read a reference supplied only in the query', () {
    final uri = Uri.parse(
      'https://dashboard.example/github/connection?reference=private-reference',
    );

    expectInvalid(uri.fragment);
  });
}
