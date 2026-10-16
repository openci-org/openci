import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:firebase_admin_sdk/auth.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/consume_github_connection_session.dart';
import 'package:openci_server/github/create_github_connection_request.dart';
import 'package:openci_server/github/create_github_connection_session.dart';
import 'package:openci_server/github/github_connection_session_table.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

import '../../../../../routes/_middleware.dart' as root;
import '../../../../../routes/teams/[id]/github/session.dart' as route;

class _MockFirebaseApp extends Mock implements FirebaseApp {}

class _MockAuth extends Mock implements Auth {}

class _MockDecodedIdToken extends Mock implements DecodedIdToken {}

class _MockStdout extends Mock implements Stdout {}

void main() {
  test(
    'rejects an unauthenticated caller before accessing the database',
    () async {
      final context = TestRequestContext(
        path: '/teams/team-1/github/session',
        method: HttpMethod.post,
        body: jsonEncode({
          'userId': 'user-1',
          'reference': 'private-reference',
        }),
      );
      context.provide<String?>(null);

      final response = await route.onRequest(context.context, 'team-1');

      expect(response.statusCode, HttpStatus.unauthorized);
      expect(await response.json(), {
        'success': false,
        'error': 'Authentication required',
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
    },
  );

  test(
    'rejects GET before reading authentication or database providers',
    () async {
      final context = TestRequestContext(path: '/teams/team-1/github/session');

      final response = await route.onRequest(context.context, 'team-1');

      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
    },
  );

  group('authenticated requests', () {
    late AppDatabase db;
    late String reference;
    late DriftGitHubConnectionSession session;

    setUp(() async {
      db = AppDatabase(
        NativeDatabase.memory(
          setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      final now = DateTime.now().toUtc();
      await db.teamDao.createTeamAndMember(
        DriftTeam(
          id: 'team-1',
          name: 'OpenCI',
          installationIds: const [],
          aiEnabled: false,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        ),
        'user-1',
      );
      await db.teamDao.addTeamMember('team-1', 'teammate');
      await db.teamDao.createTeamAndMember(
        DriftTeam(
          id: 'team-2',
          name: 'Other team',
          installationIds: const [],
          aiEnabled: false,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        ),
        'user-1',
      );
      final created = await createGitHubConnectionSession(
        db: db,
        crypter: SecretCrypter(base64Encode(List<int>.filled(32, 1))),
        userId: 'user-1',
        teamId: 'team-1',
        githubUserId: 123,
        accessToken: 'private-github-token',
      );
      reference = created.reference;
      session = await db.select(db.gitHubConnectionSessions).getSingle();
    });

    tearDown(() => db.close());

    Future<Response> post({
      String uid = 'user-1',
      String teamId = 'team-1',
      String? body,
    }) {
      final context = TestRequestContext(
        path: '/teams/$teamId/github/session',
        method: HttpMethod.post,
        body: body ?? jsonEncode({'reference': reference}),
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(uid);
      return route.onRequest(context.context, teamId);
    }

    test('returns only safe metadata without consuming the session', () async {
      final response = await post(
        body: jsonEncode({
          'reference': reference,
          'userId': 'forged-user',
          'teamId': 'team-2',
          'githubUserId': 999,
        }),
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), {
        'success': true,
        'session': {
          'teamId': 'team-1',
          'githubUserId': 123,
          'expiresAt': session.expiresAt.toUtc().toIso8601String(),
        },
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      expect(response.headers['referrer-policy'], 'no-referrer');
      final saved = await db.select(db.gitHubConnectionSessions).getSingle();
      expect(saved.consumedAt, isNull);
      expect(saved.encryptedAccessToken, session.encryptedAccessToken);
      expect((await db.teamDao.getTeam('team-1'))!.installationIds, isEmpty);
    });

    test(
      'rejects another team member despite a forged initiating UID',
      () async {
        final response = await post(
          uid: 'teammate',
          body: jsonEncode({'reference': reference, 'userId': 'user-1'}),
        );

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {
          'success': false,
          'error': 'Invalid or expired GitHub connection session',
        });
        expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      },
    );

    test('does not treat a GitHub user ID as the Firebase UID', () async {
      await db.teamDao.addTeamMember('team-1', '123');

      final response = await post(uid: '123');

      expect(response.statusCode, HttpStatus.forbidden);
    });

    test(
      'rejects another team even when the initiator belongs to it',
      () async {
        final response = await post(
          teamId: 'team-2',
          body: jsonEncode({'reference': reference, 'teamId': 'team-1'}),
        );

        expect(response.statusCode, HttpStatus.forbidden);
      },
    );

    test('rejects an initiator who has left the team', () async {
      await (db.delete(db.teamMembers)..where(
            (member) =>
                member.userId.equals('user-1') & member.teamId.equals('team-1'),
          ))
          .go();

      final response = await post();

      expect(response.statusCode, HttpStatus.forbidden);
    });

    test('rejects an expired session', () async {
      await db
          .update(db.gitHubConnectionSessions)
          .write(
            GitHubConnectionSessionsCompanion(
              expiresAt: Value(
                DateTime.now().subtract(const Duration(minutes: 1)),
              ),
            ),
          );

      final response = await post();

      expect(response.statusCode, HttpStatus.forbidden);
    });

    test('rejects a consumed session', () async {
      expect(
        await consumeGitHubConnectionSession(
          db: db,
          reference: reference,
          userId: 'user-1',
          teamId: 'team-1',
        ),
        isTrue,
      );

      final response = await post();

      expect(response.statusCode, HttpStatus.forbidden);
    });

    test('rejects a session whose token has been cleared', () async {
      await db
          .update(db.gitHubConnectionSessions)
          .write(
            const GitHubConnectionSessionsCompanion(
              encryptedAccessToken: Value(null),
            ),
          );

      final response = await post();

      expect(response.statusCode, HttpStatus.forbidden);
    });

    test('returns the same denial for an unknown reference', () async {
      final response = await post(body: jsonEncode({'reference': 'unknown'}));

      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.json(), {
        'success': false,
        'error': 'Invalid or expired GitHub connection session',
      });
    });

    test('does not accept the pre-authorization state or request ID', () async {
      final request = await createGitHubConnectionRequest(
        db: db,
        userId: 'user-1',
        teamId: 'team-1',
      );

      final stateResponse = await post(
        body: jsonEncode({'reference': request.state}),
      );
      final idResponse = await post(
        body: jsonEncode({'reference': request.id}),
      );

      expect(stateResponse.statusCode, HttpStatus.forbidden);
      expect(idResponse.statusCode, HttpStatus.forbidden);
    });

    test('does not retrieve a session with only its initiating UID', () async {
      final response = await post(body: jsonEncode({'userId': 'user-1'}));

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await response.json(), {
        'success': false,
        'error': 'Invalid GitHub connection reference',
      });
    });

    test('rejects a non-string reference', () async {
      final response = await post(body: jsonEncode({'reference': 123}));

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('rejects a blank reference', () async {
      final response = await post(body: jsonEncode({'reference': '  '}));

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('rejects a JSON body that is not an object', () async {
      final response = await post(body: jsonEncode([reference]));

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('rejects malformed JSON without returning or logging it', () async {
      final errorOutput = _MockStdout();

      final response = await IOOverrides.runZoned(
        () => post(body: '{"reference":"$reference'),
        stderr: () => errorOutput,
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await response.json(), {
        'success': false,
        'error': 'Invalid GitHub connection reference',
      });
      expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
      verifyZeroInteractions(errorOutput);
    });

    test('does not accept the reference from a query string', () async {
      final context = TestRequestContext(
        path: '/teams/team-1/github/session?reference=$reference',
        method: HttpMethod.post,
        body: '{}',
      );
      context.provide<String?>('user-1');

      final response = await route.onRequest(context.context, 'team-1');

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test(
      'returns a generic 500 when the session table is unavailable',
      () async {
        await db.customStatement('DROP TABLE github_connection_sessions');
        final errorOutput = _MockStdout();

        final response = await IOOverrides.runZoned(
          () => post(),
          stderr: () => errorOutput,
        );

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(response.headers[HttpHeaders.cacheControlHeader], 'no-store');
        final logged = verify(
          () => errorOutput.writeln(captureAny()),
        ).captured.join('\n');
        expect(logged, contains('Failed to read GitHub connection session'));
        expect(logged, isNot(contains(reference)));
        expect(logged, isNot(contains(session.referenceHash)));
        expect(logged, isNot(contains(session.encryptedAccessToken!)));
        expect(logged, isNot(contains('no such table')));
      },
    );

    test(
      'binds HTTP requests to the UID verified from the Bearer token',
      () async {
        final firebaseApp = _MockFirebaseApp();
        final auth = _MockAuth();
        final initiatorToken = _MockDecodedIdToken();
        final teammateToken = _MockDecodedIdToken();
        when(() => firebaseApp.auth()).thenReturn(auth);
        when(() => initiatorToken.uid).thenReturn('user-1');
        when(() => initiatorToken.emailVerified).thenReturn(true);
        when(() => teammateToken.uid).thenReturn('teammate');
        when(() => teammateToken.emailVerified).thenReturn(true);
        when(
          () => auth.verifyIdToken('initiator-token', checkRevoked: false),
        ).thenAnswer((_) async => initiatorToken);
        when(
          () => auth.verifyIdToken('teammate-token', checkRevoked: false),
        ).thenAnswer((_) async => teammateToken);
        Future<Response> handler(RequestContext context) =>
            route.onRequest(context, 'team-1');
        final server = await serve(
          handler
              .use(root.databaseProvider(db))
              .use(root.authProvider(firebaseApp))
              .use(
                provider<InternalApiKeyValidator>(
                  (_) => const InternalApiKeyValidator(environment: {}),
                ),
              ),
          InternetAddress.loopbackIPv4,
          0,
        );
        addTearDown(() => server.close(force: true));
        final client = http.Client();
        addTearDown(client.close);
        final uri = Uri(
          scheme: 'http',
          host: server.address.address,
          port: server.port,
          path: '/teams/team-1/github/session',
        );
        final body = jsonEncode({'reference': reference, 'userId': 'user-1'});

        final initiatorResponse = await client.post(
          uri,
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer initiator-token',
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          body: body,
        );
        final teammateResponse = await client.post(
          uri,
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer teammate-token',
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          body: body,
        );
        final anonymousResponse = await client.post(
          uri,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: body,
        );

        expect(initiatorResponse.statusCode, HttpStatus.ok);
        expect(teammateResponse.statusCode, HttpStatus.forbidden);
        expect(anonymousResponse.statusCode, HttpStatus.unauthorized);
        verify(
          () => auth.verifyIdToken('initiator-token', checkRevoked: false),
        ).called(1);
        verify(
          () => auth.verifyIdToken('teammate-token', checkRevoked: false),
        ).called(1);
      },
    );
  });
}
