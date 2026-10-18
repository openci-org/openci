import 'package:openci_server/github/parse_github_app_installation_uri.dart';
import 'package:test/test.dart';

void main() {
  test('accepts a GitHub.com installation URL', () {
    const url = 'https://github.com/apps/openci/installations/new';

    expect(parseGitHubAppInstallationUri(url)?.toString(), url);
  });

  test('preserves a GHES installation URL including its port and path', () {
    const url = 'https://github.example:8443/apps/openci/installations/new';

    expect(parseGitHubAppInstallationUri(url)?.toString(), url);
  });

  test('accepts an installation management URL', () {
    const url = 'https://github.example/settings/installations/123';

    expect(parseGitHubAppInstallationUri(url)?.toString(), url);
  });

  test('accepts HTTP for local development', () {
    const url = 'http://localhost:8080/apps/openci/installations/new';

    expect(parseGitHubAppInstallationUri(url)?.toString(), url);
  });

  test('trims surrounding whitespace', () {
    const url = 'https://github.example/apps/openci/installations/new';

    expect(parseGitHubAppInstallationUri('  $url  ')?.toString(), url);
  });

  test('omits a missing or blank setting', () {
    expect(parseGitHubAppInstallationUri(null), isNull);
    expect(parseGitHubAppInstallationUri('   '), isNull);
  });

  test('omits a relative URL', () {
    expect(
      parseGitHubAppInstallationUri('/apps/openci/installations/new'),
      isNull,
    );
  });

  test('omits a URL without a scheme', () {
    expect(
      parseGitHubAppInstallationUri('//github.example/apps/openci'),
      isNull,
    );
  });

  test('omits a non-HTTP scheme', () {
    expect(parseGitHubAppInstallationUri('javascript:alert(1)'), isNull);
  });

  test('omits a URL without a host', () {
    expect(parseGitHubAppInstallationUri('https:///apps/openci'), isNull);
  });

  test('omits credentials in the URL', () {
    expect(
      parseGitHubAppInstallationUri(
        'https://user:password@github.example/apps/openci',
      ),
      isNull,
    );
  });

  test('omits a query string', () {
    expect(
      parseGitHubAppInstallationUri(
        'https://github.example/apps/openci?token=private',
      ),
      isNull,
    );
  });

  test('omits a fragment', () {
    expect(
      parseGitHubAppInstallationUri(
        'https://github.example/apps/openci#state=old',
      ),
      isNull,
    );
  });

  test('omits a malformed URL', () {
    expect(parseGitHubAppInstallationUri('https://[invalid'), isNull);
  });
}
