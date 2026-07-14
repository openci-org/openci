import 'package:openci_server/secret/extract_secret_name.dart';
import 'package:test/test.dart';

void main() {
  group('extractSecretNames', () {
    test('extracts secrets using dot notation', () {
      final content = 'run: echo \${{ secrets.AWS_KEY }}';
      final result = extractSecretNames(content);
      expect(result, equals({'AWS_KEY'}));
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
