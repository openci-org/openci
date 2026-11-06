import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_dart_functions/src/github_workflows.dart';
import 'package:openci_dart_functions/src/open_ci_parser.dart';
import 'package:openci_dart_functions/src/plan_jobs.dart';
import 'package:openci_dart_functions/src/planning_event.dart';
import 'package:test/test.dart';

final event = PlanningEvent.parse(
  'pull_request',
  jsonEncode({
    'action': 'synchronize',
    'number': 7,
    'installation': {'id': 30},
    'repository': {
      'id': 10,
      'name': 'app',
      'owner': {'id': 20, 'login': 'org'},
    },
    'pull_request': {
      'title': 'PR',
      'head': {
        'sha': 'a' * 40,
        'ref': 'feature',
        'repo': {'id': 10},
      },
      'base': {
        'sha': 'b' * 40,
        'ref': 'main',
        'repo': {'id': 10},
      },
    },
  }),
)!;

void main() {
  test('auto cancellation accepts only literal booleans and defaults to off', () {
    for (final value in [
      '',
      ', cancelPreviousRuns: false',
      ', cancelPreviousRuns: true',
    ]) {
      final workflow = parseOpenCIWorkflow(
        "void main() { OpenCI.init(workflowName: 'CI', ciTriggers: [CITrigger.pullRequest(branch: '*')]$value); }",
        'ci.dart',
      )!;
      expect(workflow.cancelPreviousRuns, value.endsWith('true'));
    }
    for (final value in ['null', 'flag', 'true && false', "'true'"]) {
      expect(
        () => parseOpenCIWorkflow(
          "void main() { OpenCI.init(workflowName: 'CI', ciTriggers: [CITrigger.pullRequest(branch: '*')], cancelPreviousRuns: $value); }",
          'ci.dart',
        ),
        throwsA(isA<WorkflowConfigurationException>()),
      );
    }
  });

  test(
    'only selected PR workflows opt in; push and disabled workflows retain their jobs',
    () {
      final workflows = [
        for (final enabled in [true, false])
          ParsedWorkflow(
            workflowFileName: '$enabled.dart',
            workflowName: 'CI',
            cancelPreviousRuns: enabled,
            ciTriggers: const [
              ParsedCITrigger(type: 'pullRequest', branch: '*'),
              ParsedCITrigger(type: 'push', branch: '*'),
            ],
          ),
        const ParsedWorkflow(
          workflowFileName: 'unmatched.dart',
          workflowName: 'Release',
          cancelPreviousRuns: true,
          ciTriggers: [ParsedCITrigger(type: 'pullRequest', branch: 'release')],
        ),
      ];
      final plan = planJobs(
        event: event.webhook,
        teamId: 'team',
        workflows: workflows,
      );
      expect(plan.autoCancelWorkflowFiles, {'true.dart'});

      final push = event.webhook.copyWith(
        eventType: 'push',
        triggerType: 'push',
        pullRequestNumber: null,
      );
      final pushPlan = planJobs(
        event: push,
        teamId: 'team',
        workflows: workflows,
      );
      expect(pushPlan.jobs, hasLength(2));
      expect(pushPlan.autoCancelWorkflowFiles, isEmpty);
    },
  );

  for (final scenario in [
    'current',
    'stale',
    'retargeted',
    'closed',
    'fork',
    'unavailable',
    'malformed',
  ]) {
    test(
      'PR observation handles $scenario and revokes its scoped read token',
      () async {
        var revoked = false;
        final github = GitHubWorkflows(
          apiBaseUrl: 'https://github.example.test/api/v3',
          appJwt: () => 'app-jwt',
          client: MockClient((request) async {
            expect(request.followRedirects, isFalse);
            if (request.method == 'POST') {
              expect(jsonDecode(request.body), {
                'repository_ids': [10],
                'permissions': {'pull_requests': 'read'},
              });
              return http.Response('{"token":"read-token"}', 201);
            }
            expect(request.headers['authorization'], 'Bearer read-token');
            if (request.method == 'DELETE') {
              revoked = true;
              expect(request.url.path, '/api/v3/installation/token');
              return http.Response('', 204);
            }
            expect(request.url.path, '/api/v3/repos/org/app/pulls/7');
            if (scenario == 'unavailable') return http.Response('{}', 503);
            if (scenario == 'malformed') return http.Response('{}', 200);
            return http.Response(
              jsonEncode({
                'number': 7,
                'state': scenario == 'closed' ? 'closed' : 'open',
                'head': {
                  'sha': (scenario == 'stale' ? 'c' : 'a') * 40,
                  'repo': {'id': scenario == 'fork' ? 99 : 10},
                },
                'base': {
                  'ref': scenario == 'retargeted' ? 'develop' : 'main',
                  'repo': {'id': 10},
                },
              }),
              200,
            );
          }),
        );
        if (scenario == 'fork') {
          await expectLater(
            github.observePullRequest(event),
            throwsA(isA<InvalidPlanningInput>()),
          );
        } else if (['unavailable', 'malformed'].contains(scenario)) {
          await expectLater(github.observePullRequest(event), throwsStateError);
        } else {
          expect(
            await github.observePullRequest(event),
            scenario == 'current'
                ? PullRequestObservation.current
                : scenario == 'closed'
                ? PullRequestObservation.closed
                : PullRequestObservation.stale,
          );
        }
        expect(revoked, isTrue);
      },
    );
  }
}
