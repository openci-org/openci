import 'package:dashboard/firebase/plist_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('plist_parser tests', () {
    const normalXml = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.EN">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>AIzaSyNormal</string>
	<key>GCM_SENDER_ID</key>
	<string>123456789</string>
	<key>PROJECT_ID</key>
	<string>normal-project</string>
	<key>STORAGE_BUCKET</key>
	<string>normal-project.appspot.com</string>
	<key>GOOGLE_APP_ID</key>
	<string>1:123456789:ios:abcdef</string>
</dict>
</plist>''';

    test('Normal XML parses correctly', () {
      final config = parsePlist(normalXml);
      expect(config.apiKey, 'AIzaSyNormal');
      expect(config.projectId, 'normal-project');
      expect(config.appId, '1:123456789:ios:abcdef');
    });

    test('XML with BOM parses correctly', () {
      final bomXml = '\uFEFF$normalXml';
      final config = parsePlist(bomXml);
      expect(config.apiKey, 'AIzaSyNormal');
    });

    test('XML with Comment parses correctly', () {
      const commentXml = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.EN">
<plist version="1.0">
<dict>
	<!-- This is a comment -->
	<key>API_KEY</key>
	<string>AIzaSyComment</string>
	<key>GCM_SENDER_ID</key>
	<string>123456789</string>
	<!-- Another comment -->
	<key>PROJECT_ID</key>
	<string>comment-project</string>
	<key>STORAGE_BUCKET</key>
	<string>comment-project.appspot.com</string>
	<key>GOOGLE_APP_ID</key>
	<string>1:123456789:ios:abcdef</string>
</dict>
</plist>''';
      final config = parsePlist(commentXml);
      expect(config.apiKey, 'AIzaSyComment');
    });

    test('XML with leading spaces/newlines parses correctly', () {
      final spaceXml = '   \n  $normalXml';
      final config = parsePlist(spaceXml);
      expect(config.apiKey, 'AIzaSyNormal');
    });

    test('XML with invalid syntax throws FormatException', () {
      const invalidXml = '<dict><key>API_KEY</key><string>abc';
      expect(() => parsePlist(invalidXml), throwsFormatException);
    });

    test('XML with missing keys throws FormatException', () {
      const missingKeysXml = '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>AIzaSyNormal</string>
</dict>
</plist>''';
      expect(() => parsePlist(missingKeysXml), throwsFormatException);
    });

    test('Binary plist check detects bplist00 magic number', () {
      final binaryBytes = [
        0x62,
        0x70,
        0x6C,
        0x69,
        0x73,
        0x74,
        0x30,
        0x30,
        0x01,
        0x02,
      ];
      final normalBytes = [0x3C, 0x3F, 0x78, 0x6D, 0x6C]; // '<?xml'
      expect(isBinaryPlist(binaryBytes), isTrue);
      expect(isBinaryPlist(normalBytes), isFalse);
    });

    test('UTF-16 BOM detection works', () {
      final utf16Le = [0xFF, 0xFE, 0x3C, 0x00];
      final utf16Be = [0xFE, 0xFF, 0x00, 0x3C];
      expect(isUtf16Le(utf16Le), isTrue);
      expect(isUtf16Be(utf16Le), isFalse);
      expect(isUtf16Be(utf16Be), isTrue);
      expect(isUtf16Le(utf16Be), isFalse);
    });

    test('UTF-16 decoding works correctly', () {
      // "test" string in UTF-16 LE: [BOM: FF FE] + [t: 74 00] [e: 65 00] [s: 73 00] [t: 74 00]
      final bytesLe = [
        0xFF,
        0xFE,
        0x74,
        0x00,
        0x65,
        0x00,
        0x73,
        0x00,
        0x74,
        0x00,
      ];
      // "test" string in UTF-16 BE: [BOM: FE FF] + [t: 00 74] [e: 00 65] [s: 00 73] [t: 00 74]
      final bytesBe = [
        0xFE,
        0xFF,
        0x00,
        0x74,
        0x00,
        0x65,
        0x00,
        0x73,
        0x00,
        0x74,
      ];

      expect(decodeUtf16(bytesLe, isLittleEndian: true), 'test');
      expect(decodeUtf16(bytesBe, isLittleEndian: false), 'test');
    });

    group('JSON parser tests', () {
      test('Web-style JSON parses correctly', () {
        const webJson = '''{
          "apiKey": "AIzaSyWeb",
          "appId": "1:123456:web:abc",
          "projectId": "web-project",
          "messagingSenderId": "987654",
          "storageBucket": "web.appspot.com"
        }''';
        final config = parseJsonConfig(webJson);
        expect(config.apiKey, 'AIzaSyWeb');
        expect(config.appId, '1:123456:web:abc');
        expect(config.projectId, 'web-project');
      });

      test('Android-style JSON parses correctly', () {
        const androidJson = '''{
          "project_info": {
            "project_number": "12345",
            "project_id": "android-project",
            "storage_bucket": "android.appspot.com"
          },
          "client": [
            {
              "client_info": {
                "mobilesdk_app_id": "1:12345:android:abc"
              },
              "api_key": [
                {
                  "current_key": "AIzaSyAndroid"
                }
              ]
            }
          ]
        }''';
        final config = parseJsonConfig(androidJson);
        expect(config.apiKey, 'AIzaSyAndroid');
        expect(config.appId, '1:12345:android:abc');
        expect(config.projectId, 'android-project');
        expect(config.messagingSenderId, '12345');
        expect(config.storageBucket, 'android.appspot.com');
      });

      test('Invalid JSON throws FormatException', () {
        const invalidJson = '{invalid';
        expect(() => parseJsonConfig(invalidJson), throwsFormatException);
      });

      test('JSON with missing keys throws FormatException', () {
        const missingKeysJson = '{"apiKey": "AIzaSyWeb"}';
        expect(() => parseJsonConfig(missingKeysJson), throwsFormatException);
      });
    });
  });
}
