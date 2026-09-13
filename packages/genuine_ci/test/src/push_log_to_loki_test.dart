import 'dart:convert';
import 'dart:io';

import 'package:genuine_ci/src/loki/push_log.dart';
import 'package:test/test.dart';

void main() {
  group('pushLogToLoki', () {
    late HttpServer server;
    late HttpClient client;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      client = HttpClient();
    });

    tearDown(() async {
      await server.close(force: true);
      client.close(force: true);
    });

    test('successfully pushes log to mock Loki server', () async {
      Map<String, dynamic>? receivedBody;

      server.listen((HttpRequest request) async {
        expect(request.uri.path, '/loki/api/v1/push');
        expect(request.method, 'POST');
        expect(request.headers.contentType?.mimeType, 'application/json');

        final bodyString = await utf8.decoder.bind(request).join();
        receivedBody = jsonDecode(bodyString) as Map<String, dynamic>;

        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      });

      await pushLogToLoki(
        client: client,
        lokiUrl: 'http://${server.address.host}:${server.port}',
        message: 'Test log line',
        stream: 'stdout',
        command: 'echo test',
      );

      expect(receivedBody, isNotNull);
      final streams = receivedBody!['streams'] as List;
      expect(streams.length, 1);

      final streamEntry = streams[0] as Map<String, dynamic>;
      final streamLabels = streamEntry['stream'] as Map<String, dynamic>;
      expect(streamLabels['stream'], 'stdout');
      expect(streamLabels['command'], 'echo test');
      expect(streamLabels['type'], 'step_log');

      final values = streamEntry['values'] as List;
      expect(values.length, 1);
      final logValue = values[0] as List;
      expect(logValue[1], 'Test log line');
    });

    test('throws HttpException when Loki server returns 400', () async {
      server.listen((HttpRequest request) async {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('Bad Request error message');
        await request.response.close();
      });

      expect(
        () => pushLogToLoki(
          client: client,
          lokiUrl: 'http://${server.address.host}:${server.port}',
          message: 'Failed log',
          stream: 'stderr',
        ),
        throwsA(isA<HttpException>()),
      );
    });
  });
}
