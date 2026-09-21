import 'dart:convert';
import 'dart:io';

import 'package:genuine_ci/genuine_ci.dart';
import 'package:test/test.dart';

void main() {
  group('byteStreamToLines', () {
    test('splits lines with LF', () async {
      final stream = Stream<List<int>>.fromIterable([
        utf8.encode('line1\nline2\nline3'),
      ]);

      final lines = await byteStreamToLines(stream).toList();
      expect(lines, ['line1', 'line2', 'line3']);
    });

    test('handles CRLF and CR correctly', () async {
      final stream = Stream<List<int>>.fromIterable([
        utf8.encode('line1\r\nline2\rline3'),
      ]);

      final lines = await byteStreamToLines(stream).toList();
      expect(lines, ['line1', 'line2', 'line3']);
    });

    test('handles chunked byte stream across lines', () async {
      final stream = Stream<List<int>>.fromIterable([
        utf8.encode('hel'),
        utf8.encode('lo\nwor'),
        utf8.encode('ld\n'),
      ]);

      final lines = await byteStreamToLines(stream).toList();
      expect(lines, ['hello', 'world']);
    });

    test('handles multibyte characters (Japanese)', () async {
      final stream = Stream<List<int>>.fromIterable([
        utf8.encode('こんにちは\n世界'),
      ]);

      final lines = await byteStreamToLines(stream).toList();
      expect(lines, ['こんにちは', '世界']);
    });

    test('returns empty list for empty stream', () async {
      final stream = Stream<List<int>>.empty();

      final lines = await byteStreamToLines(stream).toList();
      expect(lines, isEmpty);
    });
  });

  group('runCommand', () {
    test('completes when the command exits 0', () async {
      await runCommand(
        'echo hello',
        workingDirectory: Directory.systemTemp.path,
      );
    });

    test('runs the command in workingDirectory', () async {
      final dir = await Directory.systemTemp.createTemp('genuine_ci_test_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });

      await runCommand('pwd > pwd.txt', workingDirectory: dir.path);

      final output = File(
        '${dir.path}${Platform.pathSeparator}pwd.txt',
      ).readAsStringSync().trim();
      expect(
        await Directory(output).resolveSymbolicLinks(),
        await dir.resolveSymbolicLinks(),
      );
    });
  });
}
