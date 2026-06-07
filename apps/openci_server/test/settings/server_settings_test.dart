import 'dart:io';
import 'package:openci_server/settings/server_settings.dart';
import 'package:test/test.dart';

void main() {
  group('loadServerSettings Tests', () {
    test('parses HOST and PORT correctly', () {
      final settings = loadServerSettings(
        environment: {
          'HOST': 'any',
          'PORT': '9090',
        },
      );
      expect(settings.ip, equals(InternetAddress.anyIPv4));
      expect(settings.port, equals(9090));
    });

    test('falls back to loopback and 8080 when missing', () {
      final settings = loadServerSettings(environment: {});
      expect(settings.ip, equals(InternetAddress.loopbackIPv4));
      expect(settings.port, equals(8080));
    });

    test('falls back to 8080 on invalid port', () {
      final settings = loadServerSettings(environment: {'PORT': 'invalid'});
      expect(settings.port, equals(8080));
    });
  });
}
