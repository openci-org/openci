import 'package:openci_server/github/parse_github_api_base_uri.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes the GitHub.com API URL', () {
    final uri = parseGitHubApiBaseUri(' https://api.github.com/// ');

    expect(uri.toString(), 'https://api.github.com');
  });

  test('preserves the GHES host, port, and API path', () {
    final uri = parseGitHubApiBaseUri(
      ' https://github.example:8443/github/api/v3/// ',
    );

    expect(uri.toString(), 'https://github.example:8443/github/api/v3');
  });

  test('accepts a local HTTP endpoint', () {
    final uri = parseGitHubApiBaseUri('http://localhost:8080/api/v3/');

    expect(uri.toString(), 'http://localhost:8080/api/v3');
  });

  test('rejects a malformed URL', () {
    expect(() => parseGitHubApiBaseUri('https://[invalid'), throwsStateError);
  });

  test('rejects credentials without exposing the configured value', () {
    expect(
      () => parseGitHubApiBaseUri('https://user:private@api.github.com'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'GITHUB_API_BASE_URL must be an HTTP(S) URL without credentials, '
              'query, or fragment.',
        ),
      ),
    );
  });
}
