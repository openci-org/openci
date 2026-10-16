import 'package:openci_server/github/parse_github_connection_return_uri.dart';
import 'package:test/test.dart';

void main() {
  test('accepts a fixed HTTPS URL including its port and path', () {
    final uri = parseGitHubConnectionReturnUri(
      'https://dashboard.example:8443/openci/github/connection',
    );

    expect(
      uri.toString(),
      'https://dashboard.example:8443/openci/github/connection',
    );
  });

  test('accepts an HTTP URL for a local Dashboard', () {
    final uri = parseGitHubConnectionReturnUri(
      'http://localhost:3000/github/connection',
    );

    expect(uri.toString(), 'http://localhost:3000/github/connection');
  });

  test('trims surrounding whitespace from the setting', () {
    final uri = parseGitHubConnectionReturnUri(
      '  https://dashboard.example/  ',
    );

    expect(uri.toString(), 'https://dashboard.example/');
  });

  test('rejects a missing setting', () {
    expect(() => parseGitHubConnectionReturnUri(null), throwsStateError);
  });

  test('rejects a blank setting', () {
    expect(() => parseGitHubConnectionReturnUri('   '), throwsStateError);
  });

  test('rejects a relative URL', () {
    expect(
      () => parseGitHubConnectionReturnUri('/github/connection'),
      throwsStateError,
    );
  });

  test('rejects a URL without a scheme', () {
    expect(
      () => parseGitHubConnectionReturnUri('//dashboard.example/'),
      throwsStateError,
    );
  });

  test('rejects a non-HTTP scheme', () {
    expect(
      () => parseGitHubConnectionReturnUri('javascript:alert(1)'),
      throwsStateError,
    );
  });

  test('rejects a URL without a host', () {
    expect(
      () => parseGitHubConnectionReturnUri('https:///github/connection'),
      throwsStateError,
    );
  });

  test('rejects credentials in the URL', () {
    expect(
      () => parseGitHubConnectionReturnUri(
        'https://user:password@dashboard.example/',
      ),
      throwsStateError,
    );
  });

  test('rejects a query string', () {
    expect(
      () => parseGitHubConnectionReturnUri(
        'https://dashboard.example/?from=https://other.example',
      ),
      throwsStateError,
    );
  });

  test('rejects an existing fragment', () {
    expect(
      () => parseGitHubConnectionReturnUri(
        'https://dashboard.example/#reference=old-reference',
      ),
      throwsStateError,
    );
  });

  test('rejects a malformed URL', () {
    expect(
      () => parseGitHubConnectionReturnUri('https://[invalid'),
      throwsStateError,
    );
  });
}
