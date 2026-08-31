import 'dart:io';

import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

typedef SampleData = ({String name, int count});

void main() {
  late Directory tempDir;
  late String filePath;
  late JsonFileStore<SampleData> store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('json_file_store_test_');
    filePath = p.join(tempDir.path, 'sample.json');
    store = JsonFileStore<SampleData>(
      filePath: filePath,
      fromJson: (json) => (
        name: json['name'] as String? ?? 'default',
        count: json['count'] as int? ?? 0,
      ),
      toJson: (data) => {'name': data.name, 'count': data.count},
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('JsonFileStore get', () {
    test('returns null when file does not exist', () async {
      final data = await store.get();
      expect(data, isNull);
    });

    test('reads and deserializes data when valid JSON file exists', () async {
      final file = File(filePath);
      await file.writeAsString('{"name": "test", "count": 42}');

      final data = await store.get();
      expect(data, equals((name: 'test', count: 42)));
    });

    test('throws FormatException when file is empty', () async {
      final file = File(filePath);
      await file.writeAsString('   \n');

      expect(() => store.get(), throwsA(isA<FormatException>()));
    });

    test('throws FormatException when JSON is malformed', () async {
      final file = File(filePath);
      await file.writeAsString('{ invalid json }');

      expect(() => store.get(), throwsA(isA<FormatException>()));
    });

    test('throws FormatException when root JSON is not a Map', () async {
      final file = File(filePath);
      await file.writeAsString('["item1", "item2"]');

      expect(() => store.get(), throwsA(isA<FormatException>()));
    });
  });

  group('JsonFileStore set', () {
    test('creates file and get reads the written data', () async {
      const sample = (name: 'test', count: 42);
      await store.set(sample);

      final data = await store.get();
      expect(data, equals(sample));
    });

    test('automatically creates parent directories if not exist', () async {
      final nestedPath = p.join(tempDir.path, 'sub', 'dir', 'sample.json');
      final nestedStore = JsonFileStore<SampleData>(
        filePath: nestedPath,
        fromJson: (json) => (
          name: json['name'] as String? ?? 'default',
          count: json['count'] as int? ?? 0,
        ),
        toJson: (data) => {'name': data.name, 'count': data.count},
      );

      const sample = (name: 'nested', count: 1);
      await nestedStore.set(sample);

      expect(await File(nestedPath).exists(), isTrue);
      final data = await nestedStore.get();
      expect(data, equals(sample));
    });

    test('overwrites existing data', () async {
      await store.set((name: 'first', count: 1));
      await store.set((name: 'second', count: 2));

      final data = await store.get();
      expect(data, equals((name: 'second', count: 2)));
    });
  });
}
