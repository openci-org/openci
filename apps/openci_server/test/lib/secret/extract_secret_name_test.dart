import 'package:openci_server/secret/extract_secret_name.dart';
import 'package:test/test.dart';

void main() {
  group('extractSecretNames', () {
    test('extracts secrets using dot notation', () {
      final content = 'run: echo \${{ secrets.AWS_KEY }}';
      final result = extractSecretNames(content);
      expect(result, equals({'AWS_KEY'}));
    });

    group('Dart secret getters', () {
      const definitions = '''
        abstract final class Secrets {
          static String get ascKey =>
              Platform.environment['ASC_KEY'] ??
              (throw StateError('ASC_KEY is not set.'));
          static String get signingKey =>
              Platform.environment["custom_SIGNING_KEY"] ?? '';
          static String get unused => Platform.environment['UNUSED_KEY'] ?? '';
        }
      ''';

      test('resolves the generated getter to its environment name', () {
        expect(
          extractSecretNames(
            'final key = Secrets.ascKey;',
            secretDefinitions: definitions,
          ),
          {'ASC_KEY'},
        );
      });

      test('uses the declared name without guessing its casing', () {
        expect(
          extractSecretNames(
            'final key = Secrets.signingKey;',
            secretDefinitions: definitions,
          ),
          {'custom_SIGNING_KEY'},
        );
      });

      test('handles whitespace and deduplicates mixed reference forms', () {
        expect(
          extractSecretNames(
            "Secrets \n . ascKey; Secrets.ascKey; secrets['ASC_KEY']; "
            'secrets.OTHER_KEY;',
            secretDefinitions: definitions,
          ),
          {'ASC_KEY', 'OTHER_KEY'},
        );
      });

      test('does not match another identifier ending in Secrets', () {
        expect(
          extractSecretNames(
            'otherSecrets.ascKey;',
            secretDefinitions: definitions,
          ),
          isEmpty,
        );
      });

      test(
        'does not treat the generated file import as a secret reference',
        () {
          for (final source in [
            "import 'secrets.g.dart';",
            'import "../secrets.g.dart";',
          ]) {
            expect(extractSecretNames(source), isEmpty);
            expect(
              extractSecretNames(source, secretDefinitions: definitions),
              isEmpty,
            );
          }
        },
      );

      test('rejects a getter missing from the generated definitions', () {
        expect(
          () => extractSecretNames(
            'Secrets.unknown;',
            secretDefinitions: definitions,
          ),
          throwsStateError,
        );
      });
    });

    test('extracts secrets using bracket notation with single quotes', () {
      final content = "run: echo \${{ secrets['GITHUB_TOKEN'] }}";
      final result = extractSecretNames(content);
      expect(result, equals({'GITHUB_TOKEN'}));
    });

    test('extracts secrets using bracket notation with double quotes', () {
      final content = 'run: echo \${{ secrets["API_PASSWORD"] }}';
      final result = extractSecretNames(content);
      expect(result, equals({'API_PASSWORD'}));
    });

    test('extracts multiple secrets from multiline content', () {
      final content = '''
        name: Build
        on: push
        jobs:
          build:
            steps:
              - run: echo \${{ secrets.AWS_KEY }}
              - run: echo \${{ secrets['GITHUB_TOKEN'] }}
              - run: echo \${{ secrets["API_PASSWORD"] }}
      ''';
      final result = extractSecretNames(content);
      expect(result, equals({'AWS_KEY', 'GITHUB_TOKEN', 'API_PASSWORD'}));
    });

    test('deduplicates duplicate secrets', () {
      final content = '''
        run: echo \${{ secrets.AWS_KEY }}
        run: echo \${{ secrets.AWS_KEY }}
      ''';
      final result = extractSecretNames(content);
      expect(result, equals({'AWS_KEY'}));
    });

    test('returns empty set if no secrets found', () {
      final content = 'run: echo "hello world"';
      final result = extractSecretNames(content);
      expect(result, isEmpty);
    });

    test('extracts secrets case insensitively', () {
      final content = 'run: echo \${{ SECRETS.aws_key }}';
      final result = extractSecretNames(content);
      expect(result, equals({'aws_key'}));
    });

    test(
      'extracts secrets using bracket notation with whitespace before closing bracket',
      () {
        final content = "run: echo \${{ secrets['WHITESPACE_KEY'  ] }}";
        final result = extractSecretNames(content);
        expect(result, equals({'WHITESPACE_KEY'}));
      },
    );
  });
}
