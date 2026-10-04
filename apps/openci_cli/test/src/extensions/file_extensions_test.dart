import 'dart:convert';
import 'dart:io';

import 'package:genuineci_cli/src/extensions/file_extensions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_extensions_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AtomicFileExtension', () {
    test('writeAsStringAtomic successfully writes content', () async {
      final file = File(p.join(tempDir.path, 'test.txt'));
      await file.writeAsStringAtomic('hello world');

      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), equals('hello world'));
    });

    test('writeAsStringAtomic creates parent directories if needed', () async {
      final file = File(p.join(tempDir.path, 'nested', 'sub', 'test.txt'));
      await file.writeAsStringAtomic('nested content');

      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), equals('nested content'));
    });

    test('writeAsStringAtomic overwrites existing file', () async {
      final file = File(p.join(tempDir.path, 'test.txt'));
      await file.writeAsStringAtomic('initial');
      await file.writeAsStringAtomic('updated');

      expect(await file.readAsString(), equals('updated'));
    });

    test(
      'writeAsStringAtomic sets permissions to 0600 when chmod600 is true',
      () async {
        final file = File(p.join(tempDir.path, 'secret.txt'));
        await file.writeAsStringAtomic('secret content', chmod600: true);

        expect(await file.exists(), isTrue);
        expect(await file.readAsString(), equals('secret content'));

        if (!Platform.isWindows) {
          final stat = await file.stat();
          expect(stat.mode & 0x1ff, equals(0x180));
        }
      },
    );

    for (final failOnRename in [false, true]) {
      test(
        '${failOnRename ? 'rename' : 'write'} failure preserves the original '
        'file and removes the temporary file',
        () async {
          final file = File(p.join(tempDir.path, 'config.json'));
          await file.writeAsString('original');
          final failure = FileSystemException('Injected failure', file.path);

          Future<void> fail(File temp) async {
            if (!failOnRename) {
              await temp.writeAsString('partial replacement');
            }
            throw failure;
          }

          await expectLater(
            IOOverrides.runWithIOOverrides(
              () => file.writeAsStringAtomic('replacement'),
              _TempFileOverrides(
                file.path,
                (temp) => _TestFile(
                  temp,
                  beforeWrite: failOnRename ? null : fail,
                  beforeRename: failOnRename ? fail : null,
                ),
              ),
            ),
            throwsA(same(failure)),
          );

          expect(await file.readAsString(), 'original');
          expect(await tempDir.list().map((entry) => entry.path).toList(), [
            file.path,
          ]);
        },
      );
    }

    test('retries a collision without modifying the existing file', () async {
      final file = File(p.join(tempDir.path, 'config.json'));
      late File collision;
      var attempts = 0;

      await IOOverrides.runWithIOOverrides(
        () => file.writeAsStringAtomic('replacement'),
        _TempFileOverrides(
          file.path,
          (temp) => _TestFile(
            temp,
            beforeCreate: (candidate) async {
              if (attempts++ == 0) {
                collision = candidate;
                await candidate.writeAsString('another writer');
              }
            },
          ),
        ),
      );

      expect(attempts, greaterThanOrEqualTo(2));
      expect(await file.readAsString(), 'replacement');
      expect(await collision.readAsString(), 'another writer');
      expect(
        await tempDir.list().map((entry) => entry.path).toList(),
        unorderedEquals([file.path, collision.path]),
      );
    });

    test(
      'chmod failure preserves the original file when the temporary file '
      'has disappeared',
      () async {
        final file = File(p.join(tempDir.path, 'secret.json'));
        await file.writeAsString('original');

        await expectLater(
          IOOverrides.runWithIOOverrides(
            () => file.writeAsStringAtomic('replacement', chmod600: true),
            _TempFileOverrides(
              file.path,
              (temp) => _TestFile(
                temp,
                afterCreate: (candidate) async {
                  await candidate.delete();
                },
              ),
            ),
          ),
          throwsA(
            isA<ProcessException>()
                .having((error) => error.executable, 'executable', 'chmod')
                .having((error) => error.arguments.first, 'mode', '600')
                .having((error) => error.errorCode, 'errorCode', isNot(0)),
          ),
        );

        expect(await file.readAsString(), 'original');
        expect(await tempDir.list().map((entry) => entry.path).toList(), [
          file.path,
        ]);
      },
      skip: Platform.isWindows
          ? 'chmod is only used on POSIX platforms'
          : false,
    );

    test('cleanup failure does not hide the original error', () async {
      final file = File(p.join(tempDir.path, 'config.json'));
      await file.writeAsString('original');
      final failure = FileSystemException('Rename failed', file.path);
      late File leftover;

      await expectLater(
        IOOverrides.runWithIOOverrides(
          () => file.writeAsStringAtomic('replacement'),
          _TempFileOverrides(
            file.path,
            (temp) => _TestFile(
              temp,
              beforeRename: (_) async => throw failure,
              beforeDelete: (candidate) async {
                leftover = candidate;
                throw FileSystemException('Delete failed', candidate.path);
              },
            ),
          ),
        ),
        throwsA(same(failure)),
      );

      expect(await file.readAsString(), 'original');
      expect(await leftover.readAsString(), 'replacement');
    });
  });
}

// Intercept only this operation's temporary files; all other I/O stays real.
final class _TempFileOverrides extends IOOverrides {
  _TempFileOverrides(this.targetPath, this.wrap);

  final String targetPath;
  final File Function(File) wrap;

  @override
  File createFile(String path) {
    final file = super.createFile(path);
    return path.startsWith('$targetPath.tmp.') ? wrap(file) : file;
  }
}

class _TestFile implements File {
  _TestFile(
    this._file, {
    this.beforeCreate,
    this.afterCreate,
    this.beforeWrite,
    this.beforeRename,
    this.beforeDelete,
  });

  final File _file;
  final Future<void> Function(File)? beforeCreate;
  final Future<void> Function(File)? afterCreate;
  final Future<void> Function(File)? beforeWrite;
  final Future<void> Function(File)? beforeRename;
  final Future<void> Function(File)? beforeDelete;

  @override
  String get path => _file.path;

  @override
  Future<bool> exists() => _file.exists();

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async {
    await beforeCreate?.call(_file);
    await _file.create(recursive: recursive, exclusive: exclusive);
    await afterCreate?.call(_file);
    return this;
  }

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    await beforeWrite?.call(_file);
    await _file.writeAsString(
      contents,
      mode: mode,
      encoding: encoding,
      flush: flush,
    );
    return this;
  }

  @override
  Future<File> rename(String newPath) async {
    await beforeRename?.call(_file);
    return _file.rename(newPath);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    await beforeDelete?.call(_file);
    return _file.delete(recursive: recursive);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
