import 'package:openci_server/request/mime.dart';
import 'package:test/test.dart';

void main() {
  group('getContentType', () {
    test('resolves correct mime-types for known extensions', () {
      expect(getContentType('test.ipa'), equals('application/octet-stream'));
      expect(getContentType('test.zip'), equals('application/zip'));
      expect(getContentType('test.xml'), equals('application/xml'));
      expect(getContentType('test.plist'), equals('application/xml'));
      expect(
        getContentType('test.unknown'),
        equals('application/octet-stream'),
      );
      expect(getContentType('TEST.ZIP'), equals('application/zip'));
    });
  });
}
