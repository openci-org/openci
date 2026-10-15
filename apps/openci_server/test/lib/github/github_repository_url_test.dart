import 'package:openci_server/github/github_repository_url.dart';
import 'package:test/test.dart';

void main() {
  group('githubRepositoryBaseUrl', () {
    for (final (apiUrl, repositoryUrl) in [
      ('https://api.github.com', 'https://github.com'),
      (' https://api.github.com/ ', 'https://github.com'),
      ('https://github.example.com/api/v3', 'https://github.example.com'),
      ('https://github.example.com/api/v3/', 'https://github.example.com'),
      (
        'https://github.example.com:8443/github/api/v3/',
        'https://github.example.com:8443/github',
      ),
      ('http://github.local:8080/api/v3', 'http://github.local:8080'),
      ('https://github.example.com/', 'https://github.example.com'),
    ]) {
      test('derives $repositoryUrl from $apiUrl', () {
        expect(
          githubRepositoryBaseUrl(environment: {'GITHUB_API_BASE_URL': apiUrl}),
          repositoryUrl,
        );
      });
    }

    for (final apiUrl in [
      null,
      '',
      ' ',
      'github.example.com/api/v3',
      'https:///api/v3',
      'https://[invalid',
      'file:///tmp/repository',
      'https://user:password@github.example.com/api/v3',
      'https://github.example.com/api/v3?token=value',
      'https://github.example.com/api/v3#fragment',
    ]) {
      test('rejects missing or invalid configuration: $apiUrl', () {
        expect(
          () => githubRepositoryBaseUrl(
            environment: {'GITHUB_API_BASE_URL': ?apiUrl},
          ),
          throwsStateError,
        );
      });
    }
  });
}
