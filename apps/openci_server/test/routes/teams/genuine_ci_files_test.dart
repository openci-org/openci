import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:test/test.dart';

import '../../../routes/teams/[id]/repositories/[repo]/genuine-ci-files.dart'
    as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockTeamDao extends Mock implements TeamDao {}

void main() {
  group('GET /teams/[id]/repositories/[repo]/genuine-ci-files', () {
    late RequestContext context;
    late Request request;
    late AppDatabase db;
    late TeamDao teamDao;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      db = _MockAppDatabase();
      teamDao = _MockTeamDao();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => context.read<AppDatabase>()).thenReturn(db);
      when(() => db.teamDao).thenReturn(teamDao);
      when(() => request.uri).thenReturn(
        Uri.parse('http://localhost/teams/team123/repositories/my-repo/genuine-ci-files?ref=main'),
      );
    });

    test('returns 401 Unauthorized when user is not authenticated', () async {
      when(() => context.read<String?>()).thenReturn(null);

      final response = await route.onRequest(context, 'team123', 'my-repo');

      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('returns 403 Forbidden when user is not a team member', () async {
      when(() => context.read<String?>()).thenReturn('user-1');
      when(() => teamDao.isTeamMember('user-1', 'team123'))
          .thenAnswer((_) async => false);

      final response = await route.onRequest(context, 'team123', 'my-repo');

      expect(response.statusCode, equals(HttpStatus.forbidden));
    });
  });
}
