import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firebase_admin_sdk/auth.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/build_job/build_job_dao.dart';
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../../routes/_middleware.dart' as root;
import '../../../../routes/builds/commits/stream.dart' as route;

class _MockDatabase extends Mock implements AppDatabase {}

class _MockTeamDao extends Mock implements TeamDao {}

class _MockBuildJobDao extends Mock implements BuildJobDao {}

class _MockFirebaseApp extends Mock implements FirebaseApp {}

class _MockAuth extends Mock implements Auth {}

void main() {
  late AppDatabase db;
  late TeamDao teams;
  late BuildJobDao builds;
  late StreamController<List<DriftBuildJob>> updates;
  late Completer<void> subscribed;
  late Completer<void> cancelled;

  setUp(() {
    db = _MockDatabase();
    teams = _MockTeamDao();
    builds = _MockBuildJobDao();
    subscribed = Completer<void>();
    cancelled = Completer<void>();
    updates = StreamController<List<DriftBuildJob>>.broadcast(
      onListen: subscribed.complete,
      onCancel: cancelled.complete,
    );
    addTearDown(updates.close);
    when(() => db.teamDao).thenReturn(teams);
    when(() => db.buildJobDao).thenReturn(builds);
    when(
      () => teams.isTeamMember('user-1', 'team-1'),
    ).thenAnswer((_) async => true);
    when(
      () => builds.watchBuildJobsForTeam(teamId: 'team-1'),
    ).thenAnswer((_) => updates.stream);
  });

  Future<Uri> startServer(Middleware authentication) async {
    final handler = route.onRequest
        .use(authentication)
        .use(provider<AppDatabase>((_) => db))
        .use(
          provider<InternalApiKeyValidator>(
            (_) => const InternalApiKeyValidator.forTesting(
              environment: {'INTERNAL_API_KEY': 'test-internal-key'},
            ),
          ),
        );
    final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    return Uri(
      scheme: 'http',
      host: server.address.address,
      port: server.port,
      path: '/builds/commits/stream',
      queryParameters: {'teamId': 'team-1'},
    );
  }

  Future<HttpClientResponse> requestUpgrade(Uri uri, {String? token}) async {
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client.getUrl(uri);
    request.headers
      ..set(HttpHeaders.connectionHeader, 'Upgrade')
      ..set(HttpHeaders.upgradeHeader, 'websocket')
      ..set('Sec-WebSocket-Version', '13')
      ..set('Sec-WebSocket-Key', 'dGhlIHNhbXBsZSBub25jZQ==');
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    return request.close();
  }

  group('GET /builds/commits/stream', () {
    test(
      'rejects anonymous requests before upgrading or reading data',
      () async {
        final uri = await startServer(root.authProvider(null));

        final response = await requestUpgrade(uri);

        expect(response.statusCode, HttpStatus.unauthorized);
        verifyZeroInteractions(db);
      },
    );

    test('rejects failed Firebase authentication before upgrading', () async {
      final app = _MockFirebaseApp();
      final auth = _MockAuth();
      when(() => app.auth()).thenReturn(auth);
      when(
        () => auth.verifyIdToken('invalid-token', checkRevoked: false),
      ).thenThrow(const FormatException('Invalid test token'));
      final uri = await startServer(root.authProvider(app));

      final response = await requestUpgrade(uri, token: 'invalid-token');

      expect(response.statusCode, HttpStatus.unauthorized);
      verifyZeroInteractions(db);
    });

    test('does not grant user stream access to an internal API key', () async {
      final uri = await startServer(root.authProvider(null));

      final response = await requestUpgrade(uri, token: 'test-internal-key');

      expect(response.statusCode, HttpStatus.unauthorized);
      verifyZeroInteractions(db);
    });

    test('requires a team ID before checking membership', () async {
      final uri = await startServer(provider<String?>((_) => 'user-1'));

      final response = await requestUpgrade(uri.replace(query: ''));

      expect(response.statusCode, HttpStatus.badRequest);
      verifyZeroInteractions(db);
    });

    test('rejects nonmembers before upgrading or subscribing', () async {
      when(
        () => teams.isTeamMember('user-1', 'team-1'),
      ).thenAnswer((_) async => false);
      final uri = await startServer(provider<String?>((_) => 'user-1'));

      final response = await requestUpgrade(uri);

      expect(response.statusCode, HttpStatus.forbidden);
      verifyZeroInteractions(builds);
    });

    test('streams commit updates for authenticated team members', () async {
      final uri = await startServer(provider<String?>((_) => 'user-1'));
      final socket = await WebSocket.connect(
        uri.replace(scheme: 'ws').toString(),
      );
      addTearDown(socket.close);
      final messages = StreamIterator(socket);
      addTearDown(messages.cancel);
      await subscribed.future.timeout(const Duration(seconds: 5));
      final job = BuildJob(
        id: 'build-1',
        status: BuildJobStatus.SUCCESS,
        owner: 'openci-org',
        repo: 'example',
        workflowName: 'CI',
        workflowFileName: 'ci.dart',
        teamId: 'team-1',
        commitSha: 'commit-1',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

      updates.add([job.toDrift()]);

      expect(
        await messages.moveNext().timeout(const Duration(seconds: 5)),
        isTrue,
      );
      expect(jsonDecode(messages.current as String), [
        containsPair('commitSha', 'commit-1'),
      ]);

      updates.add([]);

      expect(
        await messages.moveNext().timeout(const Duration(seconds: 5)),
        isTrue,
      );
      expect(jsonDecode(messages.current as String), isEmpty);
    });

    test('cancels the database subscription when the client closes', () async {
      final uri = await startServer(provider<String?>((_) => 'user-1'));
      final socket = await WebSocket.connect(
        uri.replace(scheme: 'ws').toString(),
      );
      addTearDown(socket.close);
      await subscribed.future.timeout(const Duration(seconds: 5));

      await socket.close();

      await cancelled.future.timeout(const Duration(seconds: 5));
      expect(updates.hasListener, isFalse);
    });
  });
}
