import 'package:genuine_ci_cli/src/generator/secrets_code_generator.dart';
import 'package:test/test.dart';

void main() {
  group('SecretsCodeGenerator', () {
    const generator = SecretsCodeGenerator();

    test('toCamelCase formats various naming conventions correctly', () {
      expect(
        SecretsCodeGenerator.toCamelCase('SLACK_WEBHOOK_URL'),
        'slackWebhookUrl',
      );
      expect(
        SecretsCodeGenerator.toCamelCase('app-store-key'),
        'appStoreKey',
      );
      expect(
        SecretsCodeGenerator.toCamelCase('FIREBASE_AUTH_KEY_V2'),
        'firebaseAuthKeyV2',
      );
      expect(
        SecretsCodeGenerator.toCamelCase('alreadyCamelCase'),
        'alreadycamelcase',
      );
      expect(
        SecretsCodeGenerator.toCamelCase('API_TOKEN'),
        'apiToken',
      );
      expect(
        SecretsCodeGenerator.toCamelCase('123_NUMBER_KEY'),
        's123NumberKey',
      );
      expect(
        SecretsCodeGenerator.toCamelCase('default'),
        'default_',
      );
      expect(
        SecretsCodeGenerator.toCamelCase('class'),
        'class_',
      );
    });

    test('generates valid Dart code for empty list', () {
      final code = generator.generate([]);
      expect(code, contains('abstract final class Secrets {'));
      expect(code, contains('// No secrets registered yet.'));
    });

    test('generates getters for provided secret names', () {
      final code = generator.generate([
        'SLACK_WEBHOOK_URL',
        'APP_STORE_KEY',
        'APP_STORE_KEY',
      ]);

      expect(code, contains('abstract final class Secrets {'));
      expect(code, contains('/// Secret key: `APP_STORE_KEY`'));
      expect(code, contains('static String get appStoreKey =>'));
      expect(code, contains("Platform.environment['APP_STORE_KEY'] ??"));
      expect(
        code,
        contains(
          "Secret 'APP_STORE_KEY' is not set in environment.",
        ),
      );

      expect(code, contains('/// Secret key: `SLACK_WEBHOOK_URL`'));
      expect(code, contains('static String get slackWebhookUrl =>'));
    });

    test('handles collisions with numbered suffixes', () {
      final code = generator.generate([
        'foo_bar',
        'foo-bar',
      ]);

      expect(code, contains('static String get fooBar =>'));
      expect(code, contains('static String get fooBar_2 =>'));
    });
  });
}
