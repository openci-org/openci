import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

class _UnavailableDatabase implements AppDatabase {
  var accesses = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    accesses++;
    throw StateError('private database connection detail');
  }
}

class DatabaseFailureEndpoint {
  const DatabaseFailureEndpoint(
    this.path,
    this.method,
    this.handle, {
    this.body = '{}',
    this.uid = 'user-1',
    this.headers = const {},
    this.configure,
  });

  final String path;
  final HttpMethod method;
  final FutureOr<Response> Function(RequestContext) handle;
  final String body;
  final String uid;
  final Map<String, String> headers;
  final void Function(TestRequestContext)? configure;
}

final databaseFailureJob = DriftBuildJob(
  id: 'job-1',
  status: BuildJobStatus.QUEUED,
  owner: 'owner',
  repo: 'repo',
  workflowName: 'build',
  workflowFileName: 'build.dart',
  teamId: 'team-1',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void testDatabaseFailures(List<DatabaseFailureEndpoint> endpoints) {
  final checkedPaths = <String>{};
  for (final endpoint in endpoints) {
    test(
      '${endpoint.method} ${endpoint.path} hides database failures',
      () async {
        final database = _UnavailableDatabase();
        final context = TestRequestContext(
          path: endpoint.path,
          method: endpoint.method,
          body: endpoint.body,
          headers: endpoint.headers,
        );
        context.provide<AppDatabase>(database);
        context.provide<String?>(endpoint.uid);
        context.provide<DriftBuildJob>(databaseFailureJob);
        endpoint.configure?.call(context);

        final response = await endpoint.handle(context.context);

        expect(database.accesses, greaterThan(0));
        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
      },
    );

    if (checkedPaths.add(Uri.parse(endpoint.path).path)) {
      test(
        'PUT ${endpoint.path} is rejected before accessing the database',
        () async {
          final database = _UnavailableDatabase();
          final context = TestRequestContext(
            path: endpoint.path,
            method: HttpMethod.put,
          );
          context.provide<AppDatabase>(database);

          final response = await endpoint.handle(context.context);

          expect(response.statusCode, HttpStatus.methodNotAllowed);
          expect(database.accesses, 0);
        },
      );
    }
  }
}
