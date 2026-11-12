import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_workflows/macos_release_publisher.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late File archive;
  const bytes = [1, 2, 3, 4];
  final signature = base64Encode(List.filled(64, 1));

  String appcast({String? url, int build = 42}) =>
      '''
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
<channel><item><sparkle:version>$build</sparkle:version>
<enclosure url="${url ?? releaseUrl(archiveObject(build, 'OpenCI-2.0.0-42.zip'))}" sparkle:edSignature="$signature" length="4"/>
</item></channel></rss>''';

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('openci-publisher-test-');
    archive = File('${directory.path}/OpenCI-2.0.0-42.zip');
    await archive.writeAsBytes(bytes);
  });
  tearDown(() => directory.delete(recursive: true));

  http.Response feed(int build, String generation) => http.Response(
    jsonEncode({
      'generation': generation,
      'metadata': {'buildNumber': '$build'},
    }),
    200,
  );
  http.Response archiveMetadata() => http.Response(
    jsonEncode({
      'size': '4',
      'metadata': {'sha256': sha256.convert(bytes).toString()},
    }),
    200,
  );
  bool isFeed(http.Request request) =>
      request.url.pathSegments.last == releaseFeedObject ||
      request.url.queryParameters['name'] == releaseFeedObject;

  Future<bool> publish(
    http.Client client,
    http.Client publicClient, {
    String? xml,
  }) => MacosReleasePublisher(client, publicClient).publish(
    archive: archive,
    appcast: xml ?? appcast(),
    buildNumber: 42,
    version: '2.0.0',
  );

  test(
    'publishes feed only after upload verification and public download check',
    () async {
      final events = <String>[];
      final client = MockClient((request) async {
        if (request.method == 'GET' && isFeed(request)) {
          events.add('read-feed');
          return feed(41, '7');
        }
        if (request.method == 'POST' &&
            request.url.queryParameters['uploadType'] == 'resumable') {
          events.add('reserve');
          expect(request.url.queryParameters['ifGenerationMatch'], '0');
          return http.Response(
            '',
            200,
            headers: {
              'location': 'https://storage.googleapis.com/upload/session',
            },
          );
        }
        if (request.method == 'PUT') {
          events.add('upload');
          expect(request.bodyBytes, bytes);
          return http.Response('{}', 200);
        }
        if (request.method == 'GET') {
          events.add('verify');
          expect(
            request.url.pathSegments.last,
            archiveObject(42, archive.uri.pathSegments.last),
          );
          return archiveMetadata();
        }
        events.add('publish-feed');
        expect(request.url.queryParameters['ifGenerationMatch'], '7');
        expect(request.body, contains('no-cache, max-age=0, must-revalidate'));
        return http.Response('{}', 200);
      });
      final public = MockClient((request) async {
        events.add('public-head');
        expect(request.method, 'HEAD');
        expect(request.headers['authorization'], isNull);
        return http.Response('', 200, headers: {'content-length': '4'});
      });
      expect(await publish(client, public), isTrue);
      expect(events, [
        'read-feed',
        'reserve',
        'upload',
        'verify',
        'public-head',
        'publish-feed',
      ]);
    },
  );

  test('does not replace a newer or already published build', () async {
    for (final current in [42, 43]) {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(isFeed(request), isTrue);
        return feed(current, '8');
      });
      final public = MockClient(
        (_) async => fail('No public request expected'),
      );
      expect(await publish(client, public), isFalse);
    }
  });

  test(
    'losing a concurrent feed update cannot roll back a newer release',
    () async {
      var reads = 0;
      var feedWrites = 0;
      final client = MockClient((request) async {
        if (request.method == 'GET' && isFeed(request)) {
          return ++reads == 1 ? feed(40, '7') : feed(43, '9');
        }
        if (request.method == 'POST' && isFeed(request)) {
          feedWrites++;
          return http.Response('', 412);
        }
        if (request.method == 'POST') {
          return http.Response(
            '',
            200,
            headers: {
              'location': 'https://storage.googleapis.com/upload/session',
            },
          );
        }
        return request.method == 'GET'
            ? archiveMetadata()
            : http.Response('{}', 200);
      });
      final public = MockClient(
        (_) async => http.Response('', 200, headers: {'content-length': '4'}),
      );
      expect(await publish(client, public), isFalse);
      expect(feedWrites, 1);
    },
  );

  test('does not advertise an archive users cannot download', () async {
    final client = MockClient((request) async {
      if (request.method == 'GET' && isFeed(request)) return feed(41, '7');
      if (request.method == 'POST') {
        expect(isFeed(request), isFalse);
        return http.Response(
          '',
          200,
          headers: {
            'location': 'https://storage.googleapis.com/upload/session',
          },
        );
      }
      return request.method == 'GET'
          ? archiveMetadata()
          : http.Response('{}', 200);
    });
    final public = MockClient((_) async => http.Response('', 403));
    await expectLater(publish(client, public), throwsStateError);
  });

  test(
    'does not send authenticated upload bytes to an unexpected host',
    () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'storage.googleapis.com');
        if (request.method == 'GET') return feed(41, '7');
        expect(request.method, 'POST');
        return http.Response(
          '',
          200,
          headers: {'location': 'https://unexpected.invalid/upload/session'},
        );
      });
      final public = MockClient(
        (_) async => fail('No public request expected'),
      );
      await expectLater(publish(client, public), throwsStateError);
    },
  );

  test(
    'rejects a feed pointing to a different artifact before making requests',
    () async {
      final client = MockClient(
        (_) async => fail('Invalid appcast must not be uploaded'),
      );
      await expectLater(
        publish(
          client,
          client,
          xml: appcast(url: 'https://unexpected.invalid/OpenCI.zip'),
        ),
        throwsStateError,
      );
    },
  );

  test('stops if an upload fails without changing the feed', () async {
    final client = MockClient((request) async {
      if (request.method == 'GET') return feed(41, '7');
      expect(isFeed(request), isFalse);
      return http.Response('', 500);
    });
    final public = MockClient((_) async => fail('No public request expected'));
    await expectLater(publish(client, public), throwsStateError);
  });
}
