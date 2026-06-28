import 'package:openci_server/device/mobile_config_helper.dart';
import 'package:test/test.dart';

void main() {
  group('escapeXml', () {
    test('escapes XML special characters correctly', () {
      expect(escapeXml('hello & world'), equals('hello &amp; world'));
      expect(escapeXml('a < b > c'), equals('a &lt; b &gt; c'));
      expect(escapeXml('say "hello"'), equals('say &quot;hello&quot;'));
      expect(escapeXml("it's test"), equals('it&apos;s test'));
      expect(
        escapeXml('nested & "special" <chars>'),
        equals('nested &amp; &quot;special&quot; &lt;chars&gt;'),
      );
    });

    test('returns the same string when there are no special characters', () {
      expect(escapeXml('hello world 123'), equals('hello world 123'));
    });
  });

  group('extractUdid', () {
    test('successfully extracts UDID from plist', () {
      final xml = '<key>UDID</key><string>test-udid-12345</string>';
      expect(extractUdid(xml), equals('test-udid-12345'));
    });

    test('returns null when UDID key is missing', () {
      final xml = '<key>PRODUCT</key><string>iPhone</string>';
      expect(extractUdid(xml), isNull);
    });

    test('trims whitespaces around UDID', () {
      final xml = '<key>UDID</key>\n<string>  test-udid-12345  </string>';
      expect(extractUdid(xml), equals('test-udid-12345'));
    });
  });

  group('extractProduct', () {
    test('successfully extracts PRODUCT from plist', () {
      final xml = '<key>PRODUCT</key><string>iPhone14,2</string>';
      expect(extractProduct(xml), equals('iPhone14,2'));
    });

    test('returns Unknown when PRODUCT key is missing', () {
      final xml = '<key>UDID</key><string>test-udid</string>';
      expect(extractProduct(xml), equals('Unknown'));
    });
  });

  group('extractOsVersion', () {
    test('successfully extracts VERSION from plist', () {
      final xml = '<key>VERSION</key><string>16.5</string>';
      expect(extractOsVersion(xml), equals('16.5'));
    });

    test('returns Unknown when VERSION key is missing', () {
      final xml = '<key>UDID</key><string>test-udid</string>';
      expect(extractOsVersion(xml), equals('Unknown'));
    });
  });
}
