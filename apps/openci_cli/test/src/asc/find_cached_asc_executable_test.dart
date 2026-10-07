import 'dart:ffi';
import 'dart:io';

import 'package:genuineci_cli/src/asc/find_cached_asc_executable.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late Directory cache;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('genuineci-asc-cache-');
    cache = Directory(p.join(root.path, 'cache'));
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  File cachedFile({
    String version = ascVersion,
    String target = 'macOS_arm64',
  }) => File(p.join(cache.path, 'tools', 'asc', version, target, 'asc'));

  Future<File> writeFixture(File file) async {
    await file.parent.create(recursive: true);
    return file.writeAsString('not an executable');
  }

  Future<File?> find({Abi abi = Abi.macosArm64}) =>
      findCachedAscExecutable(cacheDirectory: cache, abi: abi);

  test('returns null without creating a missing cache directory', () async {
    expect(await find(), isNull);
    expect(await root.list().toList(), isEmpty);
  });

  test('locates the Apple Silicon Mac file without changing it', () async {
    final file = await writeFixture(cachedFile());

    final found = await find();

    expect(found?.path, file.absolute.path);
    expect(await file.readAsString(), 'not an executable');
  });

  test('ignores files outside the pinned version and current target', () async {
    await writeFixture(cachedFile(version: '5.10.0'));
    await writeFixture(cachedFile(target: 'linux_arm64'));
    await writeFixture(File(p.join(cache.path, 'asc')));

    expect(await find(), isNull);
    expect(await cachedFile().exists(), isFalse);
  });

  test('does not accept a directory in place of the executable', () async {
    final directory = Directory(cachedFile().path);
    await directory.create(recursive: true);

    expect(await find(), isNull);
    expect(await directory.exists(), isTrue);
  });

  for (final dangling in [false, true]) {
    test(
      'does not follow a ${dangling ? 'dangling' : 'regular'} symlink',
      () async {
        final target = File(p.join(root.path, 'linked-asc'));
        if (!dangling) await writeFixture(target);
        final file = cachedFile();
        await file.parent.create(recursive: true);
        final link = await Link(file.path).create(target.path);

        expect(await find(), isNull);
        expect(await link.target(), target.path);
      },
      skip: Platform.isWindows,
    );
  }

  for (final abi in [Abi.macosX64, Abi.linuxArm64]) {
    test('rejects $abi without creating a cache', () async {
      await expectLater(find(abi: abi), throwsUnsupportedError);
      expect(await root.list().toList(), isEmpty);
    });
  }
}
