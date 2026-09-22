import 'package:build_job_planner/build_job_planner.dart';
import 'package:test/test.dart';

void main() {
  group('parseOpenCiWorkflow', () {
    for (final args in [
      "workflowName: 'CI'",
      "ciTriggers: [CiTrigger.push(branch: 'main')]",
      "workflowName: 'CI', ciTriggers: [CiTrigger.push()]",
      "workflowName: 'CI', ciTriggers: [CiTrigger.unknown(branch: 'main')]",
      "workflowName: 'CI', ciTriggers: [SomethingElse.push(branch: 'main')]",
      "workflowName: 'CI', ciTriggers: [const SomethingElse.push(branch: 'main')]",
      "workflowName: 'CI', ciTriggers: CiTrigger.push(branch: 'main')",
      "workflowName: 'CI', ciTriggers: triggers",
      "workflowName: 'CI', ciTriggers: [CiTrigger.push(branch: 'main'), trigger]",
      "workflowName: 'CI', ciTriggers: [CiTrigger.push(branch: 'main'), ...triggers]",
      "workflowName: 'CI', ciTriggers: [if (enabled) CiTrigger.push(branch: 'main')]",
      "workflowName: 'CI', ciTriggers: [CiTrigger.push(branch: 'main'), CiTrigger.pullRequest()]",
      "workflowName: name, ciTriggers: [CiTrigger.push(branch: 'main')]",
      r"workflowName: 'CI $name', ciTriggers: [CiTrigger.push(branch: 'main')]",
      r"workflowName: 'CI', ciTriggers: [CiTrigger.push(branch: 'release/$version')]",
    ]) {
      test('does not schedule an incomplete or dynamic definition: $args', () {
        final workflow = parseOpenCiWorkflow(
          'void main() { OpenCI.init($args); }',
          'ci.dart',
        );

        expect(workflow, isNull);
      });
    }

    test('ignores unrelated init calls and workflow text in comments', () {
      final workflow = parseOpenCiWorkflow('''
        // OpenCI.init(workflowName: 'Comment', ciTriggers: [CiTrigger.push(branch: '*')]);
        void main() {
          SomethingElse.init(workflowName: 'Other', ciTriggers: [CiTrigger.push(branch: '*')]);
        }
      ''', 'ci.dart');

      expect(workflow, isNull);
    });

    test('successfully parses OpenCI.init with push trigger', () {
      const source = '''
import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Unit Tests',
    ciTriggers: [CiTrigger.push(branch: 'main')],
  );

  await openCI.flutter.unitTests();
}
''';

      final workflow = parseOpenCiWorkflow(source, 'unit_test.dart');

      expect(workflow, isNotNull);
      expect(workflow!.workflowName, equals('Unit Tests'));
      expect(workflow.workflowFileName, equals('unit_test.dart'));
      expect(workflow.ciTriggers.single.type, equals('push'));
      expect(workflow.ciTriggers.single.branch, equals('main'));
    });

    test('successfully parses OpenCI.init with pullRequest trigger', () {
      const source = '''
import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'PR Check',
    ciTriggers: [CiTrigger.pullRequest(branch: 'feature/*')],
  );
}
''';

      final workflow = parseOpenCiWorkflow(source, 'pr_check.dart');

      expect(workflow, isNotNull);
      expect(workflow!.workflowName, equals('PR Check'));
      expect(workflow.workflowFileName, equals('pr_check.dart'));
      expect(workflow.ciTriggers.single.type, equals('pullRequest'));
      expect(workflow.ciTriggers.single.branch, equals('feature/*'));
    });

    test('matches both pull requests and pushes with multiple triggers', () {
      final workflow = parseOpenCiWorkflow('''
Future<void> main() async {
  await OpenCI.init(
    workflowName: 'Dashboard CI',
    ciTriggers: [
      CiTrigger.pullRequest(branch: 'develop'),
      CiTrigger.push(branch: 'develop'),
    ],
  );
}
''', 'dashboard_ci.dart');

      expect(workflow, isNotNull);
      expect(workflow!.ciTriggers, hasLength(2));
      expect(
        workflow.matches(eventType: 'pull_request', branch: 'develop'),
        isTrue,
      );
      expect(workflow.matches(eventType: 'push', branch: 'develop'), isTrue);
      expect(workflow.matches(eventType: 'push', branch: 'main'), isFalse);
      expect(
        workflow.matches(eventType: 'pull_request', branch: 'main'),
        isFalse,
      );
    });

    for (final triggers in [
      "const [CiTrigger.push(branch: 'main')]",
      "[const CiTrigger.push(branch: 'main')]",
      "<CiTrigger>[CiTrigger.push(branch: 'main')]",
    ]) {
      test('parses constant and typed triggers: $triggers', () {
        final workflow = parseOpenCiWorkflow('''
void main() {
  OpenCI.init(workflowName: 'CI', ciTriggers: $triggers);
}
''', 'ci.dart');

        expect(workflow, isNotNull);
        expect(workflow!.matches(eventType: 'push', branch: 'main'), isTrue);
        expect(workflow.matches(eventType: 'push', branch: 'develop'), isFalse);
      });
    }

    for (final invocation in [
      "GenuineCI.init(workflowName: 'CI', ciTriggers: [CiTrigger.push(branch: 'main')])",
      "OpenCI.init(workflowName: 'CI', ciTrigger: CiTrigger.push(branch: 'main'))",
      "GenuineCi.init(workflowName: 'CI', ciTriggers: [CiTrigger.push(branch: 'main')])",
      "OpenCI.init(workflowName: 'CI', ciTriggers: [CITrigger.push(branch: 'main')])",
      "OpenCI.init(workflowName: 'CI', ciTriggers: [const CITrigger.push(branch: 'main')])",
    ]) {
      test('does not schedule legacy syntax: $invocation', () {
        final workflow = parseOpenCiWorkflow(
          'void main() { $invocation; }',
          'ci.dart',
        );

        expect(workflow, isNull);
      });
    }

    test('parses constant trigger constructors with an import prefix', () {
      final workflow = parseOpenCiWorkflow('''
import 'package:openci_workflow/openci_workflow.dart' show OpenCI;
import 'package:openci_workflow/openci_workflow.dart' as ci;

Future<void> main() async {
  await OpenCI.init(
    workflowName: 'CI',
    ciTriggers: [
      const ci.CiTrigger.pullRequest(branch: 'develop'),
      const ci.CiTrigger.push(branch: 'release/*'),
    ],
  );
}
''', 'ci.dart');

      expect(workflow, isNotNull);
      expect(workflow!.ciTriggers, hasLength(2));
      expect(
        workflow.matches(eventType: 'pull_request', branch: 'develop'),
        isTrue,
      );
      expect(workflow.matches(eventType: 'push', branch: 'release/v1'), isTrue);
      expect(workflow.matches(eventType: 'push', branch: 'develop'), isFalse);
      expect(
        workflow.matches(eventType: 'pull_request', branch: 'release/v1'),
        isFalse,
      );
    });

    test('an empty trigger list never matches an event', () {
      final workflow = parseOpenCiWorkflow('''
void main() {
  OpenCI.init(workflowName: 'CI', ciTriggers: []);
}
''', 'ci.dart');

      expect(workflow, isNotNull);
      expect(workflow!.ciTriggers, isEmpty);
      expect(workflow.matches(eventType: 'push', branch: 'main'), isFalse);
      expect(
        workflow.matches(eventType: 'pull_request', branch: 'main'),
        isFalse,
      );
    });
  });

  group('ParsedWorkflow.matches', () {
    for (final triggerType in ['workflow_dispatch', 'pull_request']) {
      test('does not match unsupported trigger types: $triggerType', () {
        final workflow = ParsedWorkflow(
          workflowFileName: 'ci.dart',
          workflowName: 'CI',
          ciTriggers: [ParsedCiTrigger(type: triggerType, branch: '*')],
        );

        expect(
          workflow.matches(eventType: triggerType, branch: 'main'),
          isFalse,
        );
      });
    }

    test('treats regex punctuation in branch patterns literally', () {
      const workflow = ParsedWorkflow(
        workflowFileName: 'ci.dart',
        workflowName: 'Release',
        ciTriggers: [
          ParsedCiTrigger(type: 'push', branch: 'release/v1.2+hotfix/*'),
        ],
      );

      expect(
        workflow.matches(eventType: 'push', branch: 'release/v1.2+hotfix/test'),
        isTrue,
      );
      expect(
        workflow.matches(eventType: 'push', branch: 'release/v1x2hotfix/test'),
        isFalse,
      );
      expect(
        workflow.matches(
          eventType: 'push',
          branch: 'prefix/release/v1.2+hotfix/test',
        ),
        isFalse,
      );
      expect(
        workflow.matches(
          eventType: 'pull_request',
          branch: 'release/v1.2+hotfix/test',
        ),
        isFalse,
      );
    });

    const pushWorkflow = ParsedWorkflow(
      workflowFileName: 'deploy.dart',
      workflowName: 'Deploy',
      ciTriggers: [ParsedCiTrigger(type: 'push', branch: 'main')],
    );

    const prWorkflow = ParsedWorkflow(
      workflowFileName: 'pr.dart',
      workflowName: 'PR Check',
      ciTriggers: [ParsedCiTrigger(type: 'pullRequest', branch: 'feature/*')],
    );

    test('matches exact branch and event', () {
      expect(pushWorkflow.matches(eventType: 'push', branch: 'main'), isTrue);
      expect(
        pushWorkflow.matches(eventType: 'push', branch: 'develop'),
        isFalse,
      );
      expect(
        pushWorkflow.matches(eventType: 'pull_request', branch: 'main'),
        isFalse,
      );
    });

    test('matches wildcard branch pattern', () {
      expect(
        prWorkflow.matches(eventType: 'pull_request', branch: 'feature/auth'),
        isTrue,
      );
      expect(
        prWorkflow.matches(eventType: 'pull_request', branch: 'bugfix/123'),
        isFalse,
      );
    });

    test('keeps each event paired with its own branch pattern', () {
      const workflow = ParsedWorkflow(
        workflowFileName: 'ci.dart',
        workflowName: 'CI',
        ciTriggers: [
          ParsedCiTrigger(type: 'pullRequest', branch: 'develop'),
          ParsedCiTrigger(type: 'push', branch: 'release/*'),
        ],
      );

      expect(
        workflow.matches(eventType: 'pull_request', branch: 'develop'),
        isTrue,
      );
      expect(workflow.matches(eventType: 'push', branch: 'release/v1'), isTrue);
      expect(workflow.matches(eventType: 'push', branch: 'develop'), isFalse);
      expect(
        workflow.matches(eventType: 'pull_request', branch: 'release/v1'),
        isFalse,
      );
      expect(workflow.matches(eventType: 'issues', branch: 'develop'), isFalse);
    });
  });
}
