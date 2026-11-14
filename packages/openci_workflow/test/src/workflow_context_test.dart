import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

final _head = 'a' * 40;
final _base = 'b' * 40;
final _merge = 'c' * 40;

Map<String, Object?> _push() => {
  'schemaVersion': 1,
  'event': 'push',
  'repository': {
    'owner': 'org',
    'name': 'app',
    'githubBaseUrl': 'https://github.example',
  },
  'jobId': 'job',
  'runId': 'run-dispatch',
  'runNumber': 7,
  'branch': 'develop',
  'commitSha': _head,
  'checkoutSha': _head,
};

Map<String, Object?> _pr() => {
  ..._push()
    ..remove('branch')
    ..remove('commitSha'),
  'event': 'pull_request',
  'number': 123,
  'headBranch': 'feature/context',
  'baseBranch': 'develop',
  'headSha': _head,
  'baseSha': _base,
  'checkoutSha': _merge,
};

WorkflowContext _read(Map<String, Object?> data) =>
    WorkflowContext.fromEnvironment({'OPENCI_CONTEXT': jsonEncode(data)});

void main() {
  test('local invocation is neither a push nor a pull request', () {
    expect(WorkflowContext.fromEnvironment({}), isA<LocalContext>());
    expect(
      WorkflowContext.fromEnvironment({'OPENCI_RUN_NUMBER': '7'}),
      isA<LocalContext>(),
    );
  });

  test(
    'push context exposes saved metadata and the GitHub Enterprise host',
    () {
      final context = _read(_push()) as PushContext;
      expect(context.branch, 'develop');
      expect(context.commitSha, _head);
      expect(context.checkoutSha, _head);
      expect(context.repository.owner, 'org');
      expect(context.repository.name, 'app');
      expect(
        context.repository.githubBaseUrl,
        Uri.parse('https://github.example'),
      );
      expect(context.jobId, 'job');
      expect(context.runId, 'run-dispatch');
      expect(context.runNumber, 7);
    },
  );

  test('PR context distinguishes head, base and actual merge checkout', () {
    final context = _read(_pr()) as PullRequestContext;
    expect(context.number, 123);
    expect(context.headBranch, 'feature/context');
    expect(context.baseBranch, 'develop');
    expect(context.headSha, _head);
    expect(context.baseSha, _base);
    expect(context.checkoutSha, _merge);
  });

  test(
    'tag push retains its full ref and does not match a branch deployment',
    () {
      final context =
          _read({..._push(), 'branch': 'refs/tags/develop'}) as PushContext;
      expect(context.branch, isNot('develop'));
      expect(context.branch, 'refs/tags/develop');
    },
  );

  test('additive fields in a supported schema are ignored', () {
    expect(_read({..._push(), 'futureField': true}), isA<PushContext>());
  });

  for (final change in <String, Object?>{
    'schemaVersion': 2,
    'event': 'workflow_dispatch',
    'repository': null,
    'jobId': '',
    'runId': null,
    'runNumber': 0,
    'branch': 'private-value\n',
    'commitSha': _base,
    'checkoutSha': 'private-value',
  }.entries) {
    test('rejects invalid ${change.key} without returning a local context', () {
      expect(
        () => _read({..._push(), change.key: change.value}),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'safe message',
            isNot(contains('private-value')),
          ),
        ),
      );
    });
  }

  for (final number in [null, '123', 0, -1, 1.5, 9007199254740992]) {
    test('rejects invalid PR number $number', () {
      expect(() => _read({..._pr(), 'number': number}), throwsStateError);
    });
  }

  for (final field in [
    'number',
    'headBranch',
    'baseBranch',
    'headSha',
    'baseSha',
  ]) {
    test('rejects missing PR field $field', () {
      expect(() => _read(_pr()..remove(field)), throwsStateError);
    });
  }

  for (final url in [
    'http://github.example',
    'https://private-token@github.example',
    'https://github.example?token=private-token',
    'https://github.example#fragment',
    'https://',
  ]) {
    test('rejects invalid repository URL $url', () {
      final data = _push();
      (data['repository'] as Map)['githubBaseUrl'] = url;
      expect(() => _read(data), throwsStateError);
    });
  }

  for (final encoded in [
    '',
    'private-invalid-json',
    'null',
    '[]',
    '{"event":"push"}',
  ]) {
    test('rejects malformed or incomplete context $encoded', () {
      expect(
        () => WorkflowContext.fromEnvironment({'OPENCI_CONTEXT': encoded}),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'safe message',
            isNot(contains('private-invalid-json')),
          ),
        ),
      );
    });
  }

  for (final marker in ['OPENCI_RUN_ID', 'OPENCI_BUILD_JOB_ID']) {
    test('missing context in CI requires an executor upgrade ($marker)', () {
      expect(
        () => WorkflowContext.fromEnvironment({marker: 'job'}),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'upgrade message',
            contains('Update the OpenCI executor'),
          ),
        ),
      );
    });
  }

  for (final marker in [
    'OPENCI_RUN_ID',
    'OPENCI_BUILD_JOB_ID',
    'OPENCI_RUN_NUMBER',
  ]) {
    test('rejects inconsistent execution identity ($marker)', () {
      expect(
        () => WorkflowContext.fromEnvironment({
          'OPENCI_CONTEXT': jsonEncode(_push()),
          marker: 'different',
        }),
        throwsStateError,
      );
    });
  }

  test('context can be injected in workflow unit tests', () {
    final context = _read(_pr());
    final ci = OpenCI(
      workflowName: 'Test',
      ciTriggers: [],
      workspacePath: '.',
      context: context,
    );
    expect(ci.context, same(context));
    expect(ci.context, same(ci.context));
  });

  test(
    'init is backward compatible; context is read lazily and cached',
    () async {
      final config = (await Isolate.packageConfig)!.toFilePath();
      final library = (await Isolate.resolvePackageUri(
        Uri.parse('package:openci_workflow/openci_workflow.dart'),
      ))!;
      final probe = library
          .resolve('../test/fixtures/read_workflow_context.dart')
          .toFilePath();
      Future<ProcessResult> run(
        Map<String, String> environment, [
        List<String> args = const [],
      ]) => Process.run(
        Platform.resolvedExecutable,
        ['--packages=$config', probe, ...args],
        environment: environment,
        includeParentEnvironment: false,
      );
      final oldExecutor = {'OPENCI_RUN_ID': 'run-dispatch'};
      expect((await run(oldExecutor, ['init-only'])).exitCode, 0);
      expect((await run(oldExecutor)).exitCode, 2);
      expect(
        (await run({'OPENCI_CONTEXT': 'invalid'}, ['init-only'])).exitCode,
        0,
      );
      final local = await run({});
      expect(local.exitCode, 0, reason: local.stderr.toString());
      expect(jsonDecode(local.stdout as String), {'event': 'local'});
      final current = await run({'OPENCI_CONTEXT': jsonEncode(_pr())});
      expect(current.exitCode, 0, reason: current.stderr.toString());
      expect(
        jsonDecode(current.stdout as String),
        _pr()..remove('schemaVersion'),
      );
    },
  );
}
