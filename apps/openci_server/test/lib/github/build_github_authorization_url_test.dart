import 'package:openci_server/github/build_github_authorization_url.dart';
import 'package:test/test.dart';

void main() {
  const clientId = 'Iv1.test-client-id';
  final redirectUri = Uri.parse('https://openci.example/github/callback');
  const state = 'connection-state';
  const codeChallenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';

  test('builds a GitHub authorization URL with S256 PKCE parameters', () {
    final url = buildGitHubAuthorizationUrl(
      clientId: clientId,
      redirectUri: redirectUri,
      state: state,
      codeChallenge: codeChallenge,
      environment: const {'GITHUB_API_BASE_URL': 'https://api.github.com'},
    );

    expect(url.origin, 'https://github.com');
    expect(url.path, '/login/oauth/authorize');
    expect(url.queryParameters, {
      'client_id': clientId,
      'redirect_uri': redirectUri.toString(),
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });
  });

  test('uses the configured GHES host without the REST API path', () {
    final url = buildGitHubAuthorizationUrl(
      clientId: clientId,
      redirectUri: redirectUri,
      state: state,
      codeChallenge: codeChallenge,
      environment: const {
        'GITHUB_API_BASE_URL': 'https://github.example.com/api/v3',
      },
    );

    expect(url.origin, 'https://github.example.com');
    expect(url.path, '/login/oauth/authorize');
    expect(url.queryParameters['code_challenge_method'], 'S256');
  });

  test('preserves the configured port and path prefix', () {
    final url = buildGitHubAuthorizationUrl(
      clientId: clientId,
      redirectUri: redirectUri,
      state: state,
      codeChallenge: codeChallenge,
      environment: const {
        'GITHUB_API_BASE_URL': 'https://github.example.com:8443/github/api/v3/',
      },
    );

    expect(url.origin, 'https://github.example.com:8443');
    expect(url.path, '/github/login/oauth/authorize');
  });

  test('encodes values without introducing extra query parameters', () {
    final callbackUri = Uri.parse(
      'https://openci.example/github%20connect/callback',
    );
    const stateWithReservedCharacters = 'state+value&scope=repo#fragment';

    final url = buildGitHubAuthorizationUrl(
      clientId: clientId,
      redirectUri: callbackUri,
      state: stateWithReservedCharacters,
      codeChallenge: codeChallenge,
      environment: const {'GITHUB_API_BASE_URL': 'https://api.github.com'},
    );

    final parsedUrl = Uri.parse(url.toString());
    expect(parsedUrl.queryParameters, {
      'client_id': clientId,
      'redirect_uri': callbackUri.toString(),
      'state': stateWithReservedCharacters,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });
    expect(parsedUrl.hasFragment, isFalse);
  });

  test('rejects a missing server API base URL', () {
    expect(
      () => buildGitHubAuthorizationUrl(
        clientId: clientId,
        redirectUri: redirectUri,
        state: state,
        codeChallenge: codeChallenge,
        environment: const {},
      ),
      throwsStateError,
    );
  });

  test('rejects server configuration containing query parameters', () {
    expect(
      () => buildGitHubAuthorizationUrl(
        clientId: clientId,
        redirectUri: redirectUri,
        state: state,
        codeChallenge: codeChallenge,
        environment: const {
          'GITHUB_API_BASE_URL': 'https://api.github.com?unexpected=value',
        },
      ),
      throwsStateError,
    );
  });
}
