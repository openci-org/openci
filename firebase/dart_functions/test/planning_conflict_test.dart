import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_dart_functions/src/data_connect.dart';
import 'package:openci_dart_functions/src/plan_jobs.dart';
import 'package:test/test.dart';

void main() {
  const conflict = {
    'path': ['pullRequestPlanning_updateMany'],
    'extensions': {'code': 'PERMISSION_DENIED'},
  };
  DataConnectPlanningStore store(Object? body, {int status = 200}) =>
      DataConnectPlanningStore(
        client: MockClient(
          (_) async => http.Response(jsonEncode(body), status),
        ),
        serviceUri: Uri.parse('https://sql.example.test'),
        githubAppId: '1',
        githubApiBaseUrl: 'https://api.github.com',
        githubBaseUrl: 'https://github.com',
      );
  Future<void> complete(DataConnectPlanningStore store) => store.complete(
    'task',
    null,
    null,
    const WorkflowPlan(),
    fence: const PlanningFence('planning', 'token'),
  );

  test(
    'recognizes the fenced completion check without private error text',
    () async {
      final response = {
        'data': null,
        'errors': [
          conflict,
          {
            'path': ['webhookTask_updateMany'],
            'extensions': {'code': 'ABORTED'},
          },
        ],
      };
      await expectLater(
        complete(store(response)),
        throwsA(isA<PlanningObservationSuperseded>()),
      );
      await expectLater(
        store(response).findConnection(30, 10),
        throwsStateError,
      );
      await expectLater(
        complete(store(response, status: 403)),
        throwsStateError,
      );
    },
  );

  test(
    'unrelated checks and malformed responses are not planning conflicts',
    () async {
      for (final error in [
        {
          ...conflict,
          'path': ['query', 'connection'],
        },
        {
          ...conflict,
          'extensions': {'code': 'UNAVAILABLE'},
        },
        {...conflict, 'path': 'pullRequestPlanning_updateMany'},
        {'message': 'PR planning observation was superseded'},
        null,
      ]) {
        await expectLater(
          complete(
            store({
              'data': null,
              'errors': [error],
            }),
          ),
          throwsStateError,
        );
      }
      await expectLater(complete(store(null)), throwsStateError);
    },
  );
}
