import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late OrchardApiClient client;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = OrchardApiClient(
      config: Config(
        serverUrl: 'http://server:8080',
        internalApiKey: 'test-api-key',
        orchardApiUrl: 'http://127.0.0.1:${server.port}/orchard/',
        orchardServiceAccountName: 'worker',
        orchardServiceAccountToken: 'orchard-token',
      ),
    );
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  group('execCommandWebSocket', () {
    test(
      'authenticates, streams split output, and closes after exit',
      () async {
        late HttpRequest request;
        final serverDone = _serve(server, (incoming, socket) {
          request = incoming;
          _sendOutput(socket, 'stdout', utf8.encode('hello '));
          _sendOutput(socket, 'stderr', utf8.encode('warning\n'), binary: true);
          final bytes = utf8.encode('日本\r\ntrailing');
          _sendOutput(socket, 'stdout', bytes.sublist(0, 1));
          _sendOutput(socket, 'stdout', bytes.sublist(1));
          socket.add(
            jsonEncode({
              'type': 'exit',
              'exit': {'code': 0},
            }),
          );
        });
        final logs = <String>[];
        const command = 'printf "a & b? 日本" | cat';

        final code = await client.execCommandWebSocket(
          vmName: 'vm /?#1',
          command: command,
          onLog: logs.add,
          waitSeconds: 42,
        );
        await serverDone;

        expect(code, 0);
        expect(logs, ['warning', 'hello 日本', 'trailing']);
        expect(request.uri.pathSegments, [
          'orchard',
          'v1',
          'vms',
          'vm /?#1',
          'exec',
        ]);
        expect(request.uri.queryParameters, {'command': command, 'wait': '42'});
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Basic ${base64Encode(utf8.encode('worker:orchard-token'))}',
        );
      },
    );

    test('returns a non-zero exit code', () async {
      final serverDone = _serve(server, (_, socket) {
        socket.add(
          jsonEncode({
            'type': 'exit',
            'exit': {'code': 23},
          }),
        );
      });

      final code = await client.execCommandWebSocket(
        vmName: 'vm-1',
        command: 'false',
        onLog: (_) {},
      );
      await serverDone;

      expect(code, 23);
    });

    test('rejects a close without exit and flushes partial output', () async {
      final serverDone = _serve(server, (_, socket) async {
        _sendOutput(socket, 'stdout', utf8.encode('last output'));
        await socket.close(WebSocketStatus.normalClosure);
      });
      final logs = <String>[];

      await expectLater(
        client.execCommandWebSocket(
          vmName: 'vm-1',
          command: 'build',
          onLog: logs.add,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('closed before exit'),
          ),
        ),
      );
      await serverDone;

      expect(logs, ['last output']);
    });

    test('reports an Orchard error and closes the connection', () async {
      final serverDone = _serve(server, (_, socket) {
        socket.add(jsonEncode({'type': 'error', 'error': 'VM not found'}));
      });

      await expectLater(
        client.execCommandWebSocket(
          vmName: 'vm-1',
          command: 'build',
          onLog: (_) {},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('VM not found'),
          ),
        ),
      );
      await serverDone;
    });

    for (final message in [
      'invalid-json',
      '[]',
      '{"type":"exit","exit":{}}',
      '{"type":"exit","exit":{"code":"0"}}',
      '{"type":"stdout","data":"!"}',
    ]) {
      test('rejects malformed message $message and closes', () async {
        final serverDone = _serve(server, (_, socket) => socket.add(message));

        await expectLater(
          client.execCommandWebSocket(
            vmName: 'vm-1',
            command: 'build',
            onLog: (_) {},
          ),
          throwsFormatException,
        );
        await serverDone;
      });
    }

    test('closes the connection when the log callback throws', () async {
      final serverDone = _serve(server, (_, socket) {
        _sendOutput(socket, 'stdout', utf8.encode('output\n'));
      });
      final error = StateError('Log callback failed');

      await expectLater(
        client.execCommandWebSocket(
          vmName: 'vm-1',
          command: 'build',
          onLog: (_) => throw error,
        ),
        throwsA(same(error)),
      );
      await serverDone;
    });

    test('propagates a rejected WebSocket handshake', () async {
      final serverDone = server.first.then((request) async {
        request.response.statusCode = HttpStatus.unauthorized;
        await request.response.close();
      });

      await expectLater(
        client.execCommandWebSocket(
          vmName: 'vm-1',
          command: 'build',
          onLog: (_) {},
        ),
        throwsA(isA<WebSocketException>()),
      );
      await serverDone;
    });
  }, timeout: const Timeout(Duration(seconds: 5)));
}

Future<void> _serve(
  HttpServer server,
  FutureOr<void> Function(HttpRequest request, WebSocket socket) handler,
) async {
  final request = await server.first;
  final socket = await WebSocketTransformer.upgrade(request);
  addTearDown(() => socket.close());
  final closed = socket.drain<void>();
  await handler(request, socket);
  await closed;
}

void _sendOutput(
  WebSocket socket,
  String type,
  List<int> bytes, {
  bool binary = false,
}) {
  final message = jsonEncode({'type': type, 'data': base64Encode(bytes)});
  socket.add(binary ? utf8.encode(message) : message);
}
