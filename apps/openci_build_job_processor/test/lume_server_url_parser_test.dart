import 'package:openci_build_job_processor/openci_build_job_processor.dart';
import 'package:test/test.dart';

void main() {
  group('parseLumeServerUrls', () {
    test('正常系: カンマ区切りのURLが正しくパースされ、トリムされること', () {
      const input =
          'http://localhost:8080, http://localhost:8081 ,http://localhost:8082';
      final result = parseLumeServerUrls(input);
      expect(result, [
        'http://localhost:8080',
        'http://localhost:8081',
        'http://localhost:8082',
      ]);
    });

    test('正常系: 空の要素が除外されること', () {
      const input = 'http://localhost:8080,, http://localhost:8081, ';
      final result = parseLumeServerUrls(input);
      expect(result, ['http://localhost:8080', 'http://localhost:8081']);
    });

    test('準正常系: null の場合は空のリストを返すこと', () {
      final result = parseLumeServerUrls(null);
      expect(result, isEmpty);
    });

    test('準正常系: 空文字列の場合は空のリストを返すこと', () {
      final result = parseLumeServerUrls('');
      expect(result, isEmpty);
    });

    test('準正常系: カンマのみの場合は空のリストを返すこと', () {
      final result = parseLumeServerUrls('  ,  ');
      expect(result, isEmpty);
    });
  });
}
