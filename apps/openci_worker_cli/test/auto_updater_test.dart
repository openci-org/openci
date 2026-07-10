import 'dart:io';

import 'package:openci_worker_cli/auto_updater.dart';
import 'package:test/test.dart';

void main() {
  group('auto_updater unit tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('openci_updater_test_');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test(
      'getInstalledVersion successfully extracts version from symbolic link (Unix style)',
      () {
        final targetPath =
            '${tempDir.path}/hosted/2.3.8/bundle/bin/openci_worker';
        final linkPath = '${tempDir.path}/openci_worker';

        Directory(
          '${tempDir.path}/hosted/2.3.8/bundle/bin',
        ).createSync(recursive: true);
        File(targetPath).writeAsStringSync('');

        final link = Link(linkPath);
        link.createSync(targetPath);

        final version = getInstalledVersion(linkPath);
        expect(version, equals('2.3.8'));
      },
    );

    test(
      'getInstalledVersion successfully extracts version from symbolic link (Windows style)',
      () {
        final targetPath =
            '${tempDir.path}\\hosted\\2.3.8-patch\\bundle\\bin\\openci_worker.exe';
        final linkPath = '${tempDir.path}\\openci_worker';

        Directory(
          '${tempDir.path}/hosted/2.3.8-patch/bundle/bin',
        ).createSync(recursive: true);
        File(
          '${tempDir.path}/hosted/2.3.8-patch/bundle/bin/openci_worker.exe',
        ).writeAsStringSync('');

        final link = Link(linkPath);
        link.createSync(targetPath);

        final version = getInstalledVersion(linkPath);
        expect(version, equals('2.3.8-patch'));
      },
    );

    test('getInstalledVersion returns null if file is not a link', () {
      final filePath = '${tempDir.path}/openci_worker';
      File(filePath).writeAsStringSync('');

      final version = getInstalledVersion(filePath);
      expect(version, isNull);
    });

    test(
      'getInstalledVersion returns null and logs error if link target cannot be read',
      () {
        final version = getInstalledVersion('/non/existent/path/that/throws');
        expect(version, isNull);
      },
    );
  });
}
