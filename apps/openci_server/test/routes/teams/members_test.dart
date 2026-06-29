import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:firebase_admin_sdk/auth.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../../routes/teams/[id]/members.dart' as route;

class MockFirebaseApp extends Mock implements FirebaseApp {}

class MockAuthService extends Mock implements Auth {}

class MockUserRecord extends Mock implements UserRecord {}

void main() {
  late AppDatabase db;
  late MockFirebaseApp mockFirebaseApp;
  late MockAuthService mockAuthService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockFirebaseApp = MockFirebaseApp();
    mockAuthService = MockAuthService();

    when(() => mockFirebaseApp.auth()).thenReturn(mockAuthService);

    await db
        .into(db.teams)
        .insert(
          DriftTeam(
            id: 'team-123',
            name: 'Test Team',
            installationIds: const [],
            aiEnabled: false,
            runNumber: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('members route', () {
    test('responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/members',
        method: HttpMethod.get,
      );
      context.provide<AppDatabase>(db);
      context.provide<FirebaseApp>(mockFirebaseApp);
      context.provide<String?>(null);

      final response = await route.onRequest(context.context, 'team-123');
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'responds with 403 Forbidden when user is not a member of the team',
      () async {
        final context = TestRequestContext(
          path: '/teams/team-123/members',
          method: HttpMethod.get,
        );
        context.provide<AppDatabase>(db);
        context.provide<FirebaseApp>(mockFirebaseApp);
        context.provide<String?>('stranger-uid');

        final response = await route.onRequest(context.context, 'team-123');
        expect(response.statusCode, equals(HttpStatus.forbidden));
      },
    );

    group('GET', () {
      test('lists team members with Firebase Auth data', () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-123',
                userId: 'member-1',
              ),
            );

        final mockUserRecord = MockUserRecord();
        when(() => mockUserRecord.email).thenReturn('member1@example.com');
        when(() => mockUserRecord.displayName).thenReturn('Member One');
        when(
          () => mockUserRecord.photoUrl,
        ).thenReturn('https://example.com/photo.jpg');

        when(
          () => mockAuthService.getUser('member-1'),
        ).thenAnswer((_) async => mockUserRecord);

        final context = TestRequestContext(
          path: '/teams/team-123/members',
          method: HttpMethod.get,
        );
        context.provide<AppDatabase>(db);
        context.provide<FirebaseApp>(mockFirebaseApp);
        context.provide<String?>('member-1');

        final response = await route.onRequest(context.context, 'team-123');
        expect(response.statusCode, equals(HttpStatus.ok));

        final json = await response.json() as Map<String, dynamic>;
        final members = json['members'] as List;
        expect(members, hasLength(1));
        expect(members.first['uid'], equals('member-1'));
        expect(members.first['email'], equals('member1@example.com'));
      });
    });

    group('POST', () {
      test(
        'adds team member directly when user exists in Firebase Auth',
        () async {
          await db
              .into(db.teamMembers)
              .insert(
                TeamMembersCompanion.insert(
                  teamId: 'team-123',
                  userId: 'member-1',
                ),
              );

          final mockUserRecord = MockUserRecord();
          when(() => mockUserRecord.uid).thenReturn('new-user-uid');

          when(
            () => mockAuthService.getUserByEmail('newuser@example.com'),
          ).thenAnswer((_) async => mockUserRecord);

          final context = TestRequestContext(
            path: '/teams/team-123/members',
            method: HttpMethod.post,
            body: '{"email": "newuser@example.com"}',
          );
          context.provide<AppDatabase>(db);
          context.provide<FirebaseApp>(mockFirebaseApp);
          context.provide<String?>('member-1');

          final response = await route.onRequest(context.context, 'team-123');
          expect(response.statusCode, equals(HttpStatus.ok));

          final isMember = await db.teamDao.isTeamMember(
            'new-user-uid',
            'team-123',
          );
          expect(isMember, isTrue);
        },
      );

      test('returns 404 when user does not exist in Firebase Auth', () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-123',
                userId: 'member-1',
              ),
            );

        when(
          () => mockAuthService.getUserByEmail('notfound@example.com'),
        ).thenThrow(Exception('user-not-found: No user record found'));

        final context = TestRequestContext(
          path: '/teams/team-123/members',
          method: HttpMethod.post,
          body: '{"email": "notfound@example.com"}',
        );
        context.provide<AppDatabase>(db);
        context.provide<FirebaseApp>(mockFirebaseApp);
        context.provide<String?>('member-1');

        final response = await route.onRequest(context.context, 'team-123');
        expect(response.statusCode, equals(HttpStatus.notFound));
      });

      test('returns 400 when user is already a member of the team', () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-123',
                userId: 'member-1',
              ),
            );
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-123',
                userId: 'existing-member-uid',
              ),
            );

        final mockUserRecord = MockUserRecord();
        when(() => mockUserRecord.uid).thenReturn('existing-member-uid');

        when(
          () => mockAuthService.getUserByEmail('existing@example.com'),
        ).thenAnswer((_) async => mockUserRecord);

        final context = TestRequestContext(
          path: '/teams/team-123/members',
          method: HttpMethod.post,
          body: '{"email": "existing@example.com"}',
        );
        context.provide<AppDatabase>(db);
        context.provide<FirebaseApp>(mockFirebaseApp);
        context.provide<String?>('member-1');

        final response = await route.onRequest(context.context, 'team-123');
        expect(response.statusCode, equals(HttpStatus.badRequest));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['error'], contains('already a member'));
      });
    });
  });
}
