import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:test/test.dart';

import '../../../routes/devices/mobile-config.dart' as route;

void main() {
  const enrollmentPath =
      '/devices/mobile-config?userId=user-123&teamId=team-123'
      '&redirectOrigin=https://dashboard.openci.org';
  const enrollmentPayload = '''
<plist><dict>
  <key>UDID</key><string>test-udid-456-longer-than-25-chars</string>
  <key>PRODUCT</key><string>iPhone15,3</string>
  <key>VERSION</key><string>17.0</string>
</dict></plist>
''';

  for (final method in [HttpMethod.get, HttpMethod.post]) {
    for (final uid in [null, 'user-123', 'other-user']) {
      test('$method returns 410 for $uid without accessing storage', () async {
        final context = TestRequestContext(
          path: enrollmentPath,
          method: method,
          body: method == HttpMethod.post ? enrollmentPayload : null,
        );
        context.provide<String?>(uid);
        // Intentionally no database provider: stale enrollment requests must
        // remain disabled after device tables and DAOs have been removed.
        final response = route.onRequest(context.context);
        expect(response.statusCode, HttpStatus.gone);
        expect(await response.json(), {
          'success': false,
          'error': 'Automatic device enrollment is disabled.',
        });
      });
    }
  }

  test('an invalid token cannot reactivate an enrollment callback', () {
    final context = TestRequestContext(
      path: enrollmentPath,
      method: HttpMethod.post,
      headers: {'Authorization': 'Bearer invalid-token'},
      body: enrollmentPayload,
    );
    expect(route.onRequest(context.context).statusCode, HttpStatus.gone);
  });

  test('returns 405 for unsupported methods', () {
    final context = TestRequestContext(
      path: '/devices/mobile-config',
      method: HttpMethod.delete,
    );
    expect(
      route.onRequest(context.context).statusCode,
      HttpStatus.methodNotAllowed,
    );
  });
}
