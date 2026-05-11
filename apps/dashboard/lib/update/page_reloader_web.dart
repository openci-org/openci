import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

void superReloadPage() {
  unawaited(_superReloadPage());
}

Future<void> _superReloadPage() async {
  try {
    final registrations = await window.navigator.serviceWorker
        .getRegistrations()
        .toDart;
    for (final registration in registrations.toDart) {
      await registration.unregister().toDart;
    }
  } catch (_) {
    // Continue; reload still helps when no SW or unregister fails.
  }

  try {
    final keys = await window.caches.keys().toDart;
    for (final key in keys.toDart) {
      await window.caches.delete(key.toDart).toDart;
    }
  } catch (_) {
    // Continue.
  }

  final href = window.location.href;
  final uri = Uri.parse(href);
  final params = Map<String, String>.from(uri.queryParameters);
  params['_openci_reload'] = DateTime.now().millisecondsSinceEpoch.toString();
  window.location.replace(uri.replace(queryParameters: params).toString());
}
