import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:test/test.dart';

void main() {
  group('parseLumeServerUrls', () {
    test('should parse comma-separated URLs and trim them', () {
      const input =
          'http://localhost:8080, http://localhost:8081 ,http://localhost:8082';
      final result = parseLumeServerUrls(input);
      expect(result, [
        'http://localhost:8080',
        'http://localhost:8081',
        'http://localhost:8082',
      ]);
    });

    test('should exclude empty elements', () {
      const input = 'http://localhost:8080,, http://localhost:8081, ';
      final result = parseLumeServerUrls(input);
      expect(result, ['http://localhost:8080', 'http://localhost:8081']);
    });

    test('should return an empty list when input is null', () {
      final result = parseLumeServerUrls(null);
      expect(result, isEmpty);
    });

    test('should return an empty list when input is an empty string', () {
      final result = parseLumeServerUrls('');
      expect(result, isEmpty);
    });

    test(
      'should return an empty list when input contains only commas and spaces',
      () {
        final result = parseLumeServerUrls('  ,  ');
        expect(result, isEmpty);
      },
    );
  });
}
