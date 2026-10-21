import 'dart:js_interop';

import 'package:web/web.dart' as web;

void Function() listenForBillingPageRestore(void Function() onRestore) {
  final listener = ((web.PageTransitionEvent event) {
    if (event.persisted) onRestore();
  }).toJS;
  web.window.addEventListener('pageshow', listener);
  return () => web.window.removeEventListener('pageshow', listener);
}
