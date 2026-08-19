import 'package:openci_server/parser/genuine_ci_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseGenuineCiWorkflow', () {
    test('successfully parses GenuineCI.init with push trigger', () {
      const source = '''
import 'package:genuine_ci/genuine_ci.dart';

Future<void> main() async {
  final genuineCI = await GenuineCI.init(
    workflowName: 'Unit Tests',
    ciTrigger: CiTrigger.push(branch: 'main'),
  );

  await FlutterCi.unitTest(genuineCI.workspacePath);
}
''';

      final workflow = parseGenuineCiWorkflow(source, 'unit_test.dart');

      expect(workflow, isNotNull);
      expect(workflow!.workflowName, equals('Unit Tests'));
      expect(workflow.workflowFileName, equals('unit_test.dart'));
      expect(workflow.triggerType, equals('push'));
      expect(workflow.triggerBranch, equals('main'));
    });

    test('successfully parses GenuineCI.init with pullRequest trigger', () {
      const source = '''
import 'package:genuine_ci/genuine_ci.dart';

Future<void> main() async {
  final genuineCI = await GenuineCi.init(
    workflowName: 'PR Check',
    ciTrigger: CiTrigger.pullRequest(branch: 'feature/*'),
  );
}
''';

      final workflow = parseGenuineCiWorkflow(source, 'pr_check.dart');

      expect(workflow, isNotNull);
      expect(workflow!.workflowName, equals('PR Check'));
      expect(workflow.workflowFileName, equals('pr_check.dart'));
      expect(workflow.triggerType, equals('pullRequest'));
      expect(workflow.triggerBranch, equals('feature/*'));
    });
  });

  group('ParsedWorkflow.matches', () {
    const pushWorkflow = ParsedWorkflow(
      workflowFileName: 'deploy.dart',
      workflowName: 'Deploy',
      triggerType: 'push',
      triggerBranch: 'main',
    );

    const prWorkflow = ParsedWorkflow(
      workflowFileName: 'pr.dart',
      workflowName: 'PR Check',
      triggerType: 'pullRequest',
      triggerBranch: 'feature/*',
    );

    test('matches exact branch and event', () {
      expect(
        pushWorkflow.matches(eventType: 'push', branch: 'main'),
        isTrue,
      );
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
  });
}
