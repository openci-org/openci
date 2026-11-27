import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

/// One of the two virtual GATT devices in a session.
enum VirtualBlePeer { a, b }

/// A loopback WebSocket bridge to two Bumble GATT peers on a virtual link.
class VirtualBleSession {
  VirtualBleSession._(this._server, this._worker, this._environment);

  final HttpServer _server;
  final Process _worker;
  final Directory _environment;
  final _started = Completer<void>();
  final _closed = Completer<void>();
  final _published = <String>{};
  final _connections = <String, WebSocket>{};
  final _connectionRequests = {
    for (final role in ['A', 'B']) role: Completer<void>(),
  };
  final _publication = {
    for (final role in ['A', 'B']) role: Completer<void>(),
  };
  Future<void>? _disposal;
  String? _failure;

  /// Loopback server on the same Mac as both iOS simulators.
  Uri get baseUri => Uri(scheme: 'ws', host: '127.0.0.1', port: _server.port);

  /// WebSocket for this peer. Each role is claimed once per session.
  Uri endpoint(VirtualBlePeer peer) =>
      baseUri.resolve('/${peer.name.toUpperCase()}');

  /// Waits until the app has published its readable characteristic value.
  ///
  /// With [connectionTimeout], the app has a separate deadline to request its
  /// WebSocket connection. The publication [timeout] then starts at that point.
  /// By default the publication timeout starts as soon as this method is called.
  Future<void> waitForPeer(
    VirtualBlePeer peer, {
    Duration timeout = const Duration(seconds: 90),
    Duration? connectionTimeout,
  }) async {
    final role = peer.name.toUpperCase();
    if (connectionTimeout != null) {
      await Future.any([
        _connectionRequests[role]!.future,
        _closed.future,
      ]).timeout(
        connectionTimeout,
        onTimeout: () => throw TimeoutException(
          'Virtual BLE peer $role did not connect to the bridge',
          connectionTimeout,
        ),
      );
    }
    if (!_closed.isCompleted && !_publication[role]!.isCompleted) {
      await Future.any([
        _publication[role]!.future,
        _closed.future,
      ]).timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Virtual BLE peer $role did not publish its GATT value',
          timeout,
        ),
      );
    }
    if (_closed.isCompleted) {
      throw StateError(_failure ?? 'Virtual BLE session closed');
    }
    if (!_published.contains(role)) {
      throw StateError(_failure ?? 'Virtual BLE peer $role disconnected');
    }
  }

  /// Closes the sockets and Python worker and removes its isolated environment.
  Future<void> dispose() => _disposal ??= _close();

  Future<void> _close() async {
    _closed.complete();
    try {
      await _server.close(force: true);
      await Future.wait(
        _connections.values.toList().map(
          (socket) => socket.close(WebSocketStatus.goingAway),
        ),
      );
    } finally {
      try {
        await _worker.stdin.close().catchError((Object _) {});
        await _worker.exitCode.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _worker.kill(ProcessSignal.sigkill);
            return _worker.exitCode;
          },
        );
      } finally {
        await _environment.delete(recursive: true);
      }
    }
  }

  void _fail(Object reason) {
    if (_closed.isCompleted) return;
    _failure = reason.toString();
    stderr.writeln('Virtual BLE: $_failure');
    unawaited(dispose().catchError((Object e) => stderr.writeln(e)));
  }

  void _fromWorker(String line) {
    final envelope = jsonDecode(line) as Map<String, dynamic>;
    if (envelope['event'] == 'started') {
      _started.complete();
      return;
    }
    final role = envelope['role'] as String;
    if (envelope['event'] == 'published') {
      if (_connections.containsKey(role)) {
        _published.add(role);
        if (!_publication[role]!.isCompleted) {
          _publication[role]!.complete();
          stdout.writeln('Virtual BLE peer $role published its GATT value.');
        }
      }
    } else {
      _connections[role]?.add(jsonEncode(envelope['frame']));
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    if (path != '/A' && path != '/B') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final role = path.substring(1);
    final connection = _connectionRequests[role]!;
    if (!WebSocketTransformer.isUpgradeRequest(request) ||
        connection.isCompleted) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    connection.complete();
    WebSocket? socket;
    try {
      socket = await WebSocketTransformer.upgrade(request);
      if (_closed.isCompleted) return;
      _connections[role] = socket;
      stdout.writeln('Virtual BLE peer $role connected.');
      await for (final packet in socket) {
        if (_closed.isCompleted) break;
        final bytes = packet is String
            ? utf8.encode(packet)
            : packet as List<int>;
        if (bytes.length > 2048) {
          await socket.close(WebSocketStatus.messageTooBig);
          return;
        }
        final frame = jsonDecode(utf8.decode(bytes));
        if (frame is! Map<String, dynamic> ||
            !const {'card', 'write', 'reply'}.contains(frame['type'])) {
          throw const FormatException('Unknown virtual BLE frame');
        }
        if (frame['type'] != 'reply') {
          final value = frame['value'];
          if (value is! String || base64Decode(value).length > 512) {
            throw const FormatException(
              'Expected a base64 GATT value of at most 512 bytes',
            );
          }
        }
        _worker.stdin.writeln(jsonEncode({'role': role, 'frame': frame}));
      }
    } on FormatException {
      await socket?.close(WebSocketStatus.invalidFramePayloadData);
    } finally {
      _connections.remove(role);
      _published.remove(role);
      if (!_closed.isCompleted) {
        if (!_publication[role]!.isCompleted) _publication[role]!.complete();
        _worker.stdin.writeln(
          jsonEncode({
            'role': role,
            'frame': {'type': 'detach'},
          }),
        );
      }
      await socket?.close();
    }
  }

  Future<void> _listen() async {
    _worker.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (!_closed.isCompleted) {
              try {
                _fromWorker(line);
              } catch (error) {
                _fail(error);
              }
            }
          },
          onError: _fail,
        );
    _worker.stderr.listen(stderr.add, onError: _fail);
    _worker.stdin.done.ignore();
    unawaited(_worker.exitCode.then((code) => _fail('Bumble exited ($code)')));
    _server.listen((request) {
      unawaited(
        _handle(request).catchError((Object error) {
          if (!_closed.isCompleted) {
            stderr.writeln('Virtual BLE client: $error');
          }
        }),
      );
    }, onError: _fail);
    await Future.any([
      _started.future,
      _closed.future,
    ]).timeout(const Duration(seconds: 30));
    if (_closed.isCompleted) {
      throw StateError(_failure ?? 'Virtual BLE session closed during startup');
    }
  }
}

/// Starts a private Python environment and a loopback server. See OpenCI.startVirtualBle.
Future<VirtualBleSession> startVirtualBle({
  required String serviceUuid,
  required String characteristicUuid,
  required String pythonExecutable,
}) async {
  final uuid = RegExp(
    r'^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$',
  );
  for (final value in [serviceUuid, characteristicUuid]) {
    if (!uuid.hasMatch(value)) {
      throw ArgumentError.value(value, 'uuid', 'Expected a 128-bit UUID');
    }
  }
  if (pythonExecutable.trim().isEmpty) {
    throw ArgumentError.value(pythonExecutable, 'pythonExecutable');
  }
  final script = await Isolate.resolvePackageUri(
    Uri.parse('package:openci_workflow/src/virtual_ble/bumble_peer.py'),
  );
  if (script == null || script.scheme != 'file') {
    throw StateError('Could not locate bundled Bumble worker');
  }
  final environment = await Directory.systemTemp.createTemp(
    'openci-virtual-ble-',
  );
  HttpServer? server;
  VirtualBleSession? session;
  try {
    await _setup(pythonExecutable, ['-m', 'venv', environment.path]);
    final python = '${environment.path}/bin/python';
    await _setup(python, [
      '-m',
      'pip',
      'install',
      '--disable-pip-version-check',
      '--no-input',
      'bumble==0.0.236',
    ]);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final worker = await Process.start(python, [
      '-u',
      script.toFilePath(),
      serviceUuid,
      characteristicUuid,
    ]);
    session = VirtualBleSession._(server, worker, environment);
    await session._listen();
    return session;
  } catch (_) {
    if (session != null) {
      await session.dispose();
    } else {
      await server?.close(force: true);
      await environment.delete(recursive: true);
    }
    rethrow;
  }
}

Future<void> _setup(String executable, List<String> arguments) async {
  final process = await Process.start(executable, arguments);
  final stdoutDrain = process.stdout.drain<void>();
  final errors = process.stderr.transform(utf8.decoder).join();
  final code = await process.exitCode.timeout(
    const Duration(minutes: 3),
    onTimeout: () async {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
      throw TimeoutException('Virtual BLE Python setup timed out: $executable');
    },
  );
  await stdoutDrain;
  final diagnostic = await errors;
  if (code != 0) {
    throw ProcessException(executable, arguments, diagnostic, code);
  }
}
