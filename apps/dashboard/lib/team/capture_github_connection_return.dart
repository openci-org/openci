import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

GitHubConnectionReturn? captureGitHubConnectionReturn({
  @visibleForTesting PlatformLocation? location,
}) {
  try {
    final browser = location ?? BrowserPlatformLocation();
    final returnPath = Uri.parse(
      browser.getBaseHref() ?? '/',
    ).resolve('github/connection').path;
    if (browser.pathname != returnPath) return null;

    final hash = browser.hash;
    final hasQuery = browser.search.isNotEmpty;
    browser.replaceState(null, '', returnPath);

    final fragment = switch (hash) {
      final String value when !hasQuery && value.startsWith('#') =>
        value.substring(1),
      _ => '',
    };
    return parseGitHubConnectionReturn(fragment);
  } catch (_) {
    throw StateError('Failed to capture GitHub connection return');
  }
}
