import 'package:openci_worker_cli/get_secret_service.dart';
import 'package:test/test.dart';

void main() {
  group('extractSecretNames', () {
    test('should extract dot notation secrets', () {
      final content = '''
      name: CI
      on: push
      jobs:
        build:
          runs-on: ubuntu-latest
          steps:
            - name: Run test
              env:
                MY_SECRET: \${{ secrets.MY_SECRET_KEY }}
                OTHER: \${{ secrets.ANOTHER_ONE }}
              run: echo "Hello"
      ''';

      final result = extractSecretNames(content);
      expect(result, containsAll(['MY_SECRET_KEY', 'ANOTHER_ONE']));
    });

    test('should extract bracket notation secrets with single quotes', () {
      final content = '''
      run: echo \${{ secrets['SINGLE_QUOTE_SECRET'] }}
      ''';

      final result = extractSecretNames(content);
      expect(result, contains('SINGLE_QUOTE_SECRET'));
    });

    test('should extract bracket notation secrets with double quotes', () {
      final content = '''
      run: echo \${{ secrets["DOUBLE_QUOTE_SECRET"] }}
      ''';

      final result = extractSecretNames(content);
      expect(result, contains('DOUBLE_QUOTE_SECRET'));
    });

    test('should be case insensitive for the word secrets', () {
      final content = '''
      run: echo \${{ SECRETS.CASE_INSENSITIVE }}
      ''';

      final result = extractSecretNames(content);
      expect(result, contains('CASE_INSENSITIVE'));
    });

    test('should return empty set if no secrets found', () {
      final content = '''
      run: echo "No secrets here"
      ''';

      final result = extractSecretNames(content);
      expect(result, isEmpty);
    });
  });
}
