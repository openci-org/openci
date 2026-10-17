@TestOn('browser')
library;

import 'package:dashboard/team/capture_github_connection_return.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  final location = _BrowserLocation();
  const returnPath = '/github/connection';
  late String originalUrl;
  late Object? originalState;

  setUp(() {
    originalUrl = '${location.pathname}${location.search}${location.hash}';
    originalState = location.state;
  });

  tearDown(() {
    location.replaceState(originalState, '', originalUrl);
  });

  test('captures the reference and clears the real browser URL', () {
    location.replaceState(null, '', '$returnPath#reference=private-reference');

    final result = captureGitHubConnectionReturn(location: location);

    expect(result!.reference, 'private-reference');
    expect(location.pathname, returnPath);
    expect(location.hash, isEmpty);
    expect(location.search, isEmpty);
    expect(location.state, isNull);
    expect(PathUrlStrategy(location).getPath(), '/github/connection');
  });

  test('removes untrusted query parameters before routing starts', () {
    location.replaceState(
      null,
      '',
      '$returnPath?reference=query-reference#reference=fragment-reference',
    );

    final result = captureGitHubConnectionReturn(location: location);

    expect(result!.error, GitHubConnectionReturnError.invalidResult);
    expect(location.pathname, returnPath);
    expect(location.hash, isEmpty);
    expect(location.search, isEmpty);
    expect(PathUrlStrategy(location).getPath(), '/github/connection');
  });
}

class _BrowserLocation extends BrowserPlatformLocation {
  // The test harness has no fixed base href like the dashboard's index.html.
  @override
  String getBaseHref() => '/';
}
