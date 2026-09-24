import 'package:openci_cli/src/commands/register/secret_name_for_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  for (final (file, expected) in [
    ('google-services.json', 'GOOGLE_SERVICES_JSON_BASE64'),
    ('GoogleService-Info.plist', 'GOOGLESERVICE_INFO_PLIST_BASE64'),
    ('signing key.p12', 'SIGNING_KEY_P12_BASE64'),
    ('.env', '_ENV_BASE64'),
    ('123.mobileprovision', '_123_MOBILEPROVISION_BASE64'),
    ('signing-日本語.p12', 'SIGNING_P12_BASE64'),
    ('LICENSE', 'LICENSE_BASE64'),
  ]) {
    test('derives an environment-compatible name for $file', () {
      expect(secretNameForFile(p.join('some', 'directory', file)), expected);
    });
  }

  test('uses only the basename on Windows', () {
    expect(
      secretNameForFile(
        r'C:\Users\someone\google-services.json',
        pathContext: p.Context(style: p.Style.windows),
      ),
      'GOOGLE_SERVICES_JSON_BASE64',
    );
  });
}
