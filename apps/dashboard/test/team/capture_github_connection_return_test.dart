import 'package:dashboard/team/capture_github_connection_return.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  test('captures the reference and replaces the current history entry', () {
    final location = _Location(
      hash: '#reference=private-reference',
      state: 'old-history-state',
    );

    final result = captureGitHubConnectionReturn(location: location);

    expect(result!.reference, 'private-reference');
    expect(result.error, isNull);
    expect(location.replacedUrl, '/github/connection');
    expect(location.replacementCount, 1);
    expect(location.hash, isEmpty);
    expect(location.search, isEmpty);
    expect(location.state, isNull);
  });

  test('captures a fixed error and clears the fragment', () {
    final location = _Location(hash: '#error=access_denied');

    final result = captureGitHubConnectionReturn(location: location);

    expect(result!.error, GitHubConnectionReturnError.accessDenied);
    expect(location.hash, isEmpty);
  });

  test('clears malformed input and returns an invalid result', () {
    final location = _Location(hash: '#reference=private-reference%');

    final result = captureGitHubConnectionReturn(location: location);

    expect(result!.error, GitHubConnectionReturnError.invalidResult);
    expect(location.hash, isEmpty);
  });

  test('rejects and removes a reference supplied only in the query', () {
    final location = _Location(search: '?reference=private-reference');

    final result = captureGitHubConnectionReturn(location: location);

    expect(result!.reference, isNull);
    expect(result.error, GitHubConnectionReturnError.invalidResult);
    expect(location.search, isEmpty);
  });

  test('rejects query parameters even when a valid fragment is present', () {
    final location = _Location(
      search: '?teamId=forged-team',
      hash: '#reference=private-reference',
    );

    final result = captureGitHubConnectionReturn(location: location);

    expect(result!.reference, isNull);
    expect(result.error, GitHubConnectionReturnError.invalidResult);
    expect(location.hash, isEmpty);
    expect(location.search, isEmpty);
  });

  test('does not modify a URL outside the connection return path', () {
    final location = _Location(
      pathname: '/runs/build-1',
      search: '?view=logs',
      hash: '#reference=unrelated-value',
      state: 'existing-state',
    );

    final result = captureGitHubConnectionReturn(location: location);

    expect(result, isNull);
    expect(location.replacementCount, 0);
    expect(location.pathname, '/runs/build-1');
    expect(location.search, '?view=logs');
    expect(location.hash, '#reference=unrelated-value');
    expect(location.state, 'existing-state');
  });

  test('honors the base path of a dashboard served under a subdirectory', () {
    final location = _Location(
      baseHref: 'https://dashboard.example/openci/',
      pathname: '/openci/github/connection',
      hash: '#reference=private-reference',
    );

    final result = captureGitHubConnectionReturn(location: location);

    expect(result!.reference, 'private-reference');
    expect(location.replacedUrl, '/openci/github/connection');
    expect(location.hash, isEmpty);
  });

  test('a return URL without a fragment has an invalid result', () {
    final result = captureGitHubConnectionReturn(location: _Location());

    expect(result!.error, GitHubConnectionReturnError.invalidResult);
  });

  test('stops with a fixed error when the URL cannot be cleared', () {
    final location = _Location(
      hash: '#reference=private-reference',
      replacementError: StateError('private-reference in browser failure'),
    );

    expect(
      () => captureGitHubConnectionReturn(location: location),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Failed to capture GitHub connection return',
        ),
      ),
    );
  });
}

class _Location extends Fake implements PlatformLocation {
  _Location({
    this.baseHref = '/',
    this.pathname = '/github/connection',
    this.search = '',
    this.hash = '',
    this.state,
    this.replacementError,
  });

  final String baseHref;
  final Object? replacementError;
  String? replacedUrl;
  int replacementCount = 0;

  @override
  String pathname;

  @override
  String search;

  @override
  String hash;

  @override
  Object? state;

  @override
  String getBaseHref() => baseHref;

  @override
  void replaceState(Object? state, String title, String url) {
    if (replacementError != null) throw replacementError!;
    replacementCount++;
    replacedUrl = url;
    this.state = state;
    pathname = url;
    search = '';
    hash = '';
  }
}
