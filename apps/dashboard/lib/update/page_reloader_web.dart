import 'dart:js_interop';

@JS('eval')
external JSAny? _eval(JSString code);

void superReloadPage() {
  _eval(
    r'''
(async () => {
  try {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    }

    if ('caches' in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
    }
  } catch (error) {
    console.warn('[OpenCI] Failed to clear web app caches before reload.', error);
  } finally {
    const url = new URL(window.location.href);
    url.searchParams.set('_openci_reload', Date.now().toString());
    window.location.replace(url.toString());
  }
})()
'''
        .toJS,
  );
}
