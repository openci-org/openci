import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:dashboard/router/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _customScheme = 'openci';

const _supportedHosts = {
  'dashboard.openci.org',
  'openci-b1b91.web.app',
};

const _deepLinkChannel = MethodChannel('org.openci.dashboard/deep_link');

final deepLinkListenerProvider = Provider<void>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }

  final router = ref.watch(routerProvider);
  final appLinks = AppLinks();

  Future<void> handleUri(Uri? uri) async {
    if (uri == null) return;
    if (uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        !_supportedHosts.contains(uri.host)) {
      return;
    }

    final location = _toAppLocation(uri);
    if (location == null) return;
    if (router.state.uri.toString() == location) return;
    router.go(location);
  }

  // Universal Links on macOS (NSUserActivity) forwarded from AppDelegate
  _deepLinkChannel.setMethodCallHandler((call) async {
    if (call.method == 'onDeepLink') {
      final urlString = call.arguments as String?;
      if (urlString != null) {
        await handleUri(Uri.parse(urlString));
      }
    }
  });
  ref.onDispose(() => _deepLinkChannel.setMethodCallHandler(null));

  unawaited(() async {
    final initialUri = await appLinks.getInitialLink();
    await handleUri(initialUri);
  }());

  // Custom URL scheme (openci://) via app_links
  final subscription = appLinks.uriLinkStream.listen((uri) {
    unawaited(handleUri(uri));
  });
  ref.onDispose(subscription.cancel);
});

/// Converts an incoming URI to an in-app route location.
///
/// Handles both Universal Links (`https://dashboard.openci.org/runs/...`)
/// and custom URL scheme (`openci://runs/...`).
///
/// For the custom scheme, `openci://runs/abc` is parsed as
/// host="runs", path="/abc", so we reconstruct the full path.
String? _toAppLocation(Uri uri) {
  final String path;
  if (uri.scheme == _customScheme) {
    path = uri.host.isNotEmpty ? '/${uri.host}${uri.path}' : uri.path;
  } else {
    path = uri.path;
  }

  if (path.isEmpty) return '/';
  if (path == '/' ||
      path.startsWith('/runs/') ||
      path.startsWith('/invite/') ||
      path == '/auth') {
    final query = uri.hasQuery ? '?${uri.query}' : '';
    final fragment = uri.hasFragment ? '#${uri.fragment}' : '';
    return '$path$query$fragment';
  }
  return null;
}
