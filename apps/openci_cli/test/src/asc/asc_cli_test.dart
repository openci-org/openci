import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:genuineci_cli/src/asc/asc_cli.dart';
import 'package:genuineci_cli/src/asc/asc_license.dart';
import 'package:genuineci_cli/src/asc/asc_release.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _Client extends http.BaseClient {
  _Client(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);

  @override
  void close() => closed = true;
}

void main() {
  final bytes = utf8.encode('verified asc test binary');
  final release = AscRelease(
    target: 'linux_amd64',
    checksum: sha256.convert(bytes).toString(),
  );
  late Directory root;
  late File cached;
  late List<http.BaseRequest> requests;
  late List<_Client> clients;
  late List<String> executableFiles;
  late Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  late Future<ProcessResult> Function(String, List<String>) processRunner;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('genuineci asc cache ');
    cached = File(
      p.join(
        root.path,
        'tools',
        'asc',
        AscRelease.version,
        release.target,
        'asc',
      ),
    );
    requests = [];
    clients = [];
    executableFiles = [];
    handler = (_) async => http.StreamedResponse(Stream.value(bytes), 200);
    processRunner = (executable, arguments) async {
      expect(executable, '/bin/chmod');
      expect(arguments.take(1), ['700']);
      expect(arguments, hasLength(2));
      expect(await File(arguments[1]).readAsBytes(), bytes);
      executableFiles.add(arguments[1]);
      return ProcessResult(1, 0, '', '');
    };
  });

  tearDown(() async {
    expect(clients.every((client) => client.closed), isTrue);
    final leftovers = await root.list(recursive: true).toList();
    expect(
      leftovers.where(
        (entry) => p.basename(entry.path).startsWith('.download-'),
      ),
      isEmpty,
    );
    await root.delete(recursive: true);
  });

  AscCli installer({AscRelease? target, Duration? timeout}) => AscCli(
    cacheDirectory: root,
    release: target ?? release,
    clientFactory: () {
      final client = _Client((request) {
        requests.add(request);
        return handler(request);
      });
      clients.add(client);
      return client;
    },
    processRunner: (executable, arguments) =>
        processRunner(executable, arguments),
    downloadTimeout: timeout ?? const Duration(seconds: 1),
  );

  Matcher failsWith(AscCliFailure failure) => throwsA(
    isA<AscCliException>().having((e) => e.failure, 'failure', failure),
  );

  Future<void> seedCache(List<int> content) async {
    await cached.parent.create(recursive: true);
    await cached.writeAsBytes(content);
  }

  test(
    'downloads the pinned asset without credentials and caches its license',
    () async {
      final file = await installer().ensureAvailable();

      expect(file.path, cached.absolute.path);
      expect(await file.readAsBytes(), bytes);
      expect(requests.single.method, 'GET');
      expect(
        requests.single.url.toString(),
        'https://github.com/rorkai/App-Store-Connect-CLI/releases/download/'
        '5.11.0/asc_5.11.0_linux_amd64',
      );
      expect(requests.single.headers, {'Accept': 'application/octet-stream'});
      expect(executableFiles, hasLength(1));
      expect(executableFiles.single, isNot(file.path));
      expect(
        await File(p.join(file.parent.path, 'LICENSE')).readAsString(),
        ascLicense,
      );
    },
  );

  test('reuses a verified cache offline and restores its license', () async {
    await seedCache(bytes);
    final modified = await cached.lastModified();
    handler = (_) async => throw StateError('must not download');

    final file = await installer().ensureAvailable();

    expect(file.path, cached.absolute.path);
    expect(await cached.lastModified(), modified);
    expect(requests, isEmpty);
    expect(clients, isEmpty);
    expect(executableFiles, [cached.absolute.path]);
    expect(
      await File(p.join(cached.parent.path, 'LICENSE')).readAsString(),
      ascLicense,
    );
  });

  test(
    'rechecks the checksum and repairs a cache changed between calls',
    () async {
      final cli = installer();
      await cli.ensureAvailable();
      await cached.writeAsString('corrupt binary');

      await cli.ensureAvailable();

      expect(requests, hasLength(2));
      expect(await cached.readAsBytes(), bytes);
      expect(executableFiles, hasLength(2));
      expect(executableFiles, everyElement(isNot(cached.path)));
    },
  );

  test('keeps the stable path absent until the download completes', () async {
    final finish = Completer<void>();
    final started = Completer<void>();
    Stream<List<int>> body() async* {
      yield bytes.take(4).toList();
      started.complete();
      await finish.future;
      yield bytes.skip(4).toList();
    }

    handler = (_) async => http.StreamedResponse(body(), 200);
    final installing = installer().ensureAvailable();
    await started.future;

    expect(await cached.exists(), isFalse);
    expect(executableFiles, isEmpty);
    finish.complete();
    await installing;

    expect(await cached.readAsBytes(), bytes);
  });

  test('discards a checksum mismatch without making it executable', () async {
    handler = (_) async =>
        http.StreamedResponse(Stream.value(utf8.encode('invalid')), 200);

    await expectLater(
      installer().ensureAvailable(),
      failsWith(AscCliFailure.checksum),
    );

    expect(await cached.exists(), isFalse);
    expect(executableFiles, isEmpty);
  });

  test(
    'can retry after a failed repair without using the corrupt cache',
    () async {
      await seedCache(utf8.encode('old corrupt data'));
      handler = (_) async => http.StreamedResponse(Stream.value(bytes), 503);
      final cli = installer();

      await expectLater(
        cli.ensureAvailable(),
        failsWith(AscCliFailure.download),
      );

      expect(await cached.readAsString(), 'old corrupt data');
      expect(executableFiles, isEmpty);
      handler = (_) async => http.StreamedResponse(Stream.value(bytes), 200);
      await cli.ensureAvailable();
      expect(await cached.readAsBytes(), bytes);
    },
  );

  for (final status in [403, 404, 500]) {
    test('cleans up a failed HTTP $status download', () async {
      handler = (_) async => http.StreamedResponse(Stream.value(bytes), status);

      await expectLater(
        installer().ensureAvailable(),
        failsWith(AscCliFailure.download),
      );

      expect(await cached.exists(), isFalse);
      expect(executableFiles, isEmpty);
    });
  }

  test('cleans up a disconnected download', () async {
    Stream<List<int>> body() async* {
      yield bytes.take(4).toList();
      throw http.ClientException('private error details');
    }

    handler = (_) async => http.StreamedResponse(body(), 200);

    await expectLater(
      installer().ensureAvailable(),
      failsWith(AscCliFailure.download),
    );

    expect(await cached.exists(), isFalse);
    expect(executableFiles, isEmpty);
  });

  test('times out while waiting for response headers', () async {
    handler = (_) => Completer<http.StreamedResponse>().future;

    await expectLater(
      installer(timeout: const Duration(milliseconds: 20)).ensureAvailable(),
      failsWith(AscCliFailure.download),
    );

    expect(await cached.exists(), isFalse);
    expect(executableFiles, isEmpty);
  });

  test('times out and cancels a stalled response body', () async {
    var cancelled = false;
    final controller = StreamController<List<int>>(
      onCancel: () => cancelled = true,
    );
    handler = (_) async => http.StreamedResponse(controller.stream, 200);

    await expectLater(
      installer(timeout: const Duration(milliseconds: 20)).ensureAvailable(),
      failsWith(AscCliFailure.download),
    );

    expect(cancelled, isTrue);
    await controller.close();
    expect(await cached.exists(), isFalse);
  });

  test('reports unavailable cache storage without downloading', () async {
    await File(p.join(root.path, 'tools')).writeAsString('not a directory');

    await expectLater(
      installer().ensureAvailable(),
      failsWith(AscCliFailure.cache),
    );

    expect(requests, isEmpty);
  });

  test('does not replace a directory at the executable path', () async {
    await Directory(cached.path).create(recursive: true);

    await expectLater(
      installer().ensureAvailable(),
      failsWith(AscCliFailure.cache),
    );

    expect(await Directory(cached.path).exists(), isTrue);
    expect(requests, isEmpty);
  });

  test(
    'does not follow an executable symlink',
    () async {
      final target = File(p.join(root.path, 'external-asc'));
      await target.writeAsBytes(bytes);
      await cached.parent.create(recursive: true);
      await Link(cached.path).create(target.path);

      await expectLater(
        installer().ensureAvailable(),
        failsWith(AscCliFailure.cache),
      );

      expect(await target.readAsBytes(), bytes);
      expect(executableFiles, isEmpty);
      expect(requests, isEmpty);
    },
    skip: Platform.isWindows
        ? 'Windows symlinks require extra privileges'
        : false,
  );

  for (final throwsException in [false, true]) {
    test(
      'does not install a binary when chmod fails ($throwsException)',
      () async {
        processRunner = (_, _) async {
          if (throwsException) throw const ProcessException('/bin/chmod', []);
          return ProcessResult(1, 1, '', 'private error details');
        };

        await expectLater(
          installer().ensureAvailable(),
          failsWith(AscCliFailure.permission),
        );

        expect(await cached.exists(), isFalse);
      },
    );
  }

  test('installs the Windows asset as asc.exe without chmod', () async {
    final windows = AscRelease(
      target: 'windows_amd64',
      checksum: release.checksum,
    );
    final file = await installer(target: windows).ensureAvailable();

    expect(p.basename(file.path), 'asc.exe');
    expect(requests.single.url.path, endsWith('/asc_5.11.0_windows_amd64.exe'));
    expect(await file.readAsBytes(), bytes);
    expect(executableFiles, isEmpty);
  });

  test(
    'concurrent installations only publish complete verified files',
    () async {
      final ready = Completer<void>();
      handler = (_) async {
        if (requests.length == 2) ready.complete();
        await ready.future;
        return http.StreamedResponse(Stream.value(bytes), 200);
      };

      final installed = await Future.wait([
        installer().ensureAvailable(),
        installer().ensureAvailable(),
      ]);

      expect(installed.map((file) => file.path).toSet(), {
        cached.absolute.path,
      });
      expect(await cached.readAsBytes(), bytes);
      expect(requests, hasLength(2));
    },
  );

  test(
    'fails on unsupported platforms without creating a cache or client',
    () async {
      await expectLater(
        AscCli(
          cacheDirectory: root,
          abi: Abi.windowsArm64,
          clientFactory: () => throw StateError('must not download'),
        ).ensureAvailable(),
        failsWith(AscCliFailure.unsupportedPlatform),
      );

      expect(await root.list().toList(), isEmpty);
    },
  );

  test(
    'sets real executable permissions for a native POSIX installation',
    () async {
      processRunner = Process.run;

      final file = await installer().ensureAvailable();

      expect((await file.stat()).mode & 0x1ff, 0x1c0);
      expect(await file.readAsBytes(), bytes);
    },
    skip: Platform.isWindows,
  );
}
