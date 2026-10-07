import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:genuineci_cli/src/asc/asc_license.dart';
import 'package:genuineci_cli/src/asc/find_cached_asc_executable.dart';
import 'package:genuineci_cli/src/asc/install_asc.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _Client extends http.BaseClient {
  _Client(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  final requests = <http.BaseRequest>[];
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return handler(request);
  }

  @override
  void close() => closed = true;
}

void main() {
  final bytes = utf8.encode('asc download fixture; never execute');
  final checksum = sha256.convert(bytes).toString();
  late Directory root;
  late Directory cache;
  late File executable;
  late List<_Client> clients;
  late Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  late Future<ProcessResult> Function(String, List<String>) processRunner;
  late int chmodCalls;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('genuineci-asc-install-');
    cache = Directory(p.join(root.path, 'cache with spaces'));
    executable = File(
      p.join(cache.path, 'tools', 'asc', '5.11.0', 'macOS_arm64', 'asc'),
    );
    clients = [];
    chmodCalls = 0;
    handler = (_) async => http.StreamedResponse(
      Stream.fromIterable([bytes.sublist(0, 5), bytes.sublist(5)]),
      200,
    );
    processRunner = (program, arguments) async {
      chmodCalls++;
      expect(program, '/bin/chmod');
      expect(arguments, hasLength(2));
      expect(arguments.first, '700');
      expect(await File(arguments.last).readAsBytes(), bytes);
      // The stable path stays absent until verification and chmod succeed.
      expect(await executable.exists(), isFalse);
      return ProcessResult(0, 0, '', '');
    };
  });

  tearDown(() async {
    expect(clients.every((client) => client.closed), isTrue);
    final leftovers = await root
        .list(recursive: true, followLinks: false)
        .toList();
    expect(
      leftovers.where(
        (entry) => p.basename(entry.path).startsWith('.download-'),
      ),
      isEmpty,
    );
    await root.delete(recursive: true);
  });

  Future<File> install({
    Abi abi = Abi.macosArm64,
    Duration timeout = const Duration(seconds: 30),
  }) => installAsc(
    cacheDirectory: cache,
    abi: abi,
    expectedChecksum: checksum,
    clientFactory: () {
      final client = _Client(handler);
      clients.add(client);
      return client;
    },
    processRunner: processRunner,
    downloadTimeout: timeout,
  );

  Matcher failure(AscInstallFailure expected) => throwsA(
    isA<AscInstallException>().having(
      (error) => error.failure,
      'failure',
      expected,
    ),
  );

  test(
    'installs the pinned download with its license after verification',
    () async {
      final installed = await install();

      expect(installed.path, executable.absolute.path);
      expect(await installed.readAsBytes(), bytes);
      expect(chmodCalls, 1);
      expect(
        await File(p.join(executable.parent.path, 'LICENSE')).readAsString(),
        ascLicense,
      );
      final request = clients.single.requests.single;
      expect(request.method, 'GET');
      expect(
        request.url.toString(),
        'https://github.com/rorkai/App-Store-Connect-CLI/releases/download/'
        '5.11.0/asc_5.11.0_macOS_arm64',
      );
      expect(request.headers['accept'], 'application/octet-stream');
      expect(request.headers.containsKey('authorization'), isFalse);
      expect(request.headers.containsKey('cookie'), isFalse);
      expect(
        (await executable.parent.list().toList()).map(
          (file) => p.basename(file.path),
        ),
        unorderedEquals(['asc', 'LICENSE']),
      );
    },
  );

  test('reuses a cached file without downloading or modifying it', () async {
    await executable.parent.create(recursive: true);
    await executable.writeAsString('existing cache');

    expect((await install()).path, executable.path);
    expect(await executable.readAsString(), 'existing cache');
    expect(clients, isEmpty);
    expect(chmodCalls, 0);
  });

  test('rejects a checksum mismatch before chmod or publication', () async {
    handler = (_) async => http.StreamedResponse(Stream.value([1, 2, 3]), 200);

    await expectLater(install(), failure(AscInstallFailure.checksum));

    expect(await executable.exists(), isFalse);
    expect(await executable.parent.list().toList(), isEmpty);
    expect(chmodCalls, 0);
  });

  for (final status in [404, 503]) {
    test('cleans up after HTTP $status', () async {
      handler = (_) async => http.StreamedResponse(Stream.value(bytes), status);

      await expectLater(install(), failure(AscInstallFailure.download));

      expect(await executable.exists(), isFalse);
      expect(chmodCalls, 0);
    });
  }

  test('cleans up a partial download and allows retry', () async {
    Stream<List<int>> interrupted() async* {
      yield bytes.sublist(0, 5);
      throw http.ClientException('connection interrupted');
    }

    handler = (_) async => http.StreamedResponse(interrupted(), 200);

    await expectLater(install(), failure(AscInstallFailure.download));
    expect(await executable.parent.list().toList(), isEmpty);
    expect(chmodCalls, 0);

    handler = (_) async => http.StreamedResponse(Stream.value(bytes), 200);
    expect(await (await install()).readAsBytes(), bytes);
    expect(clients, hasLength(2));
  });

  test('cleans up after a network connection error', () async {
    handler = (_) async => throw const SocketException('offline');

    await expectLater(install(), failure(AscInstallFailure.download));
    expect(await executable.exists(), isFalse);
    expect(chmodCalls, 0);
  });

  test(
    'times out waiting for response headers and closes the client',
    () async {
      final response = Completer<http.StreamedResponse>();
      handler = (_) => response.future;

      await expectLater(
        install(timeout: const Duration(milliseconds: 20)),
        failure(AscInstallFailure.download),
      );

      expect(await executable.exists(), isFalse);
      expect(clients.single.closed, isTrue);
      response.complete(http.StreamedResponse(const Stream.empty(), 200));
    },
  );

  test('times out and removes a stalled partial response body', () async {
    var cancelled = false;
    final body = StreamController<List<int>>(onCancel: () => cancelled = true);
    body.add(bytes.sublist(0, 5));
    handler = (_) async => http.StreamedResponse(body.stream, 200);

    await expectLater(
      install(timeout: const Duration(milliseconds: 20)),
      failure(AscInstallFailure.download),
    );

    expect(await executable.exists(), isFalse);
    expect(cancelled, isTrue);
    await body.close();
  });

  for (final throws in [false, true]) {
    test('cleans up when chmod ${throws ? 'throws' : 'fails'}', () async {
      processRunner = (program, arguments) async {
        if (throws) throw ProcessException(program, arguments, 'unavailable');
        return ProcessResult(0, 1, '', 'permission denied');
      };

      await expectLater(install(), failure(AscInstallFailure.permission));
      expect(await executable.exists(), isFalse);
      expect(await executable.parent.list().toList(), isEmpty);
    });
  }

  test('cleans up if publishing the binary fails', () async {
    processRunner = (_, _) async {
      await Directory(executable.path).create();
      return ProcessResult(0, 0, '', '');
    };

    await expectLater(install(), throwsA(isA<FileSystemException>()));
    expect(await Directory(executable.path).exists(), isTrue);
  });

  test('does not replace a directory at the cache path', () async {
    await Directory(executable.path).create(recursive: true);

    await expectLater(install(), throwsA(isA<FileSystemException>()));
    expect(await Directory(executable.path).exists(), isTrue);
    expect(clients, isEmpty);
  });

  test('does not replace a symlink or write to its target', () async {
    final target = await File(
      p.join(root.path, 'external'),
    ).writeAsString('keep');
    await executable.parent.create(recursive: true);
    final link = await Link(executable.path).create(target.path);

    await expectLater(install(), throwsA(isA<FileSystemException>()));
    expect(await link.target(), target.path);
    expect(await target.readAsString(), 'keep');
    expect(clients, isEmpty);
  }, skip: Platform.isWindows);

  test('rejects non-Apple-Silicon targets before any side effects', () async {
    await expectLater(install(abi: Abi.macosX64), throwsUnsupportedError);
    expect(await cache.exists(), isFalse);
    expect(clients, isEmpty);
    expect(chmodCalls, 0);
  });

  test(
    'sets actual owner-only executable permissions without running asc',
    () async {
      processRunner = Process.run;

      final installed = await install();

      expect((await installed.stat()).mode & 0x1ff, 0x1c0);
      expect(await findCachedAscExecutable(cacheDirectory: cache), isNotNull);
    },
    skip: Abi.current() != Abi.macosArm64,
  );
}
