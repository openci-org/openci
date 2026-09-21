import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openci_workflow/src/loki/push_log.dart';
import 'package:test/test.dart';

void main() {
  group('pushLogToLoki', () {
    late HttpServer server;
    late http.Client client;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      client = http.Client();
    });

    tearDown(() async {
      await server.close(force: true);
      client.close();
    });

    test('successfully pushes log to mock Loki server', () async {
      const message = 'ビルド開始 🚀\nnext line';
      Map<String, dynamic>? receivedBody;

      server.listen((HttpRequest request) async {
        expect(request.uri.path, '/loki/api/v1/push');
        expect(request.method, 'POST');
        expect(request.headers.contentType?.mimeType, 'application/json');
        expect(request.headers.contentType?.charset, 'utf-8');

        final bodyString = await utf8.decoder.bind(request).join();
        receivedBody = jsonDecode(bodyString) as Map<String, dynamic>;

        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      });

      await pushLogToLoki(
        client: client,
        lokiUrl: 'http://${server.address.host}:${server.port}',
        message: message,
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
      expect(logValue[1], message);
    });

    test('pushes a batch without changing timestamps or messages', () async {
      const values = [
        ['1789430400000000000', 'first'],
        ['1789430400100000000', 'ビルド 🚀'],
      ];
      Map<String, dynamic>? receivedBody;
      server.listen((request) async {
        receivedBody =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      });

      await pushLogsToLoki(
        client: client,
        lokiUrl: 'http://${server.address.host}:${server.port}',
        values: values,
        stream: 'stderr',
        command: 'flutter test',
      );

      final stream = (receivedBody!['streams'] as List).single as Map;
      expect(stream['values'], values);
      expect(stream['stream'], containsPair('stream', 'stderr'));
      expect(stream['stream'], containsPair('command', 'flutter test'));
    });

    test('throws HttpException when Loki server returns 400', () async {
      const responseBody = 'ログを保存できません';
      server.listen((HttpRequest request) async {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType(
          'text',
          'plain',
          charset: 'utf-8',
        );
        request.response.write(responseBody);
        await request.response.close();
      });

      await expectLater(
        pushLogToLoki(
          client: client,
          lokiUrl: 'http://${server.address.host}:${server.port}',
          message: 'Failed log',
          stream: 'stderr',
        ),
        throwsA(
          isA<HttpException>()
              .having(
                (error) => error.message,
                'message',
                'Failed to push log to Loki (HTTP 400): $responseBody',
              )
              .having(
                (error) => error.uri,
                'uri',
                Uri.parse(
                  'http://${server.address.host}:${server.port}/loki/api/v1/push',
                ),
              ),
        ),
      );
    });

    test('keeps the shared client usable after failure and success', () async {
      var requestCount = 0;
      server.listen((request) async {
        await request.drain<void>();
        request.response.statusCode = ++requestCount == 1
            ? HttpStatus.badRequest
            : HttpStatus.noContent;
        await request.response.close();
      });

      Future<void> send() => pushLogToLoki(
        client: client,
        lokiUrl: 'http://${server.address.host}:${server.port}',
        message: 'build output',
        stream: 'stdout',
      );

      await expectLater(send(), throwsA(isA<HttpException>()));
      await send();
      await send();

      expect(requestCount, 3);
    });
  });
}
