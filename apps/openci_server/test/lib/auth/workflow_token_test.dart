import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:openci_server/auth/workflow_token.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  const key = 'server-only-key';
  final tokens = WorkflowToken(key);
  const claims = (
    jobId: 'job',
    runId: 'run',
    teamId: 'team',
    secretKeys: {'BUILD'},
  );

  void expectClaims(WorkflowTokenClaims? actual) {
    expect(actual, isNotNull);
    expect(actual!.jobId, claims.jobId);
    expect(actual.runId, claims.runId);
    expect(actual.teamId, claims.teamId);
    expect(actual.secretKeys, claims.secretKeys);
  }

  test('round trips only the named job, run, team and secret scope', () {
    final token = tokens.issue(claims);
    expectClaims(tokens.verify(token));
    expect(token, isNot(contains(key)));
    expect(WorkflowToken('other-key').verify(token), isNull);
    final pieces = token.split('.');
    pieces[1] = 'eyJ0ZWFtSWQiOiJvdGhlciJ9';
    expect(tokens.verify(pieces.join('.')), isNull);
  });

  String signed({
    String issuer = 'openci-workflow',
    String audience = 'build-number',
    Duration? expires = const Duration(minutes: 1),
    String runId = 'run',
    JWTAlgorithm algorithm = JWTAlgorithm.HS256,
  }) =>
      JWT(
        {
          'jobId': 'job',
          'runId': runId,
          'teamId': 'team',
          'secretKeys': ['BUILD'],
        },
        issuer: issuer,
        audience: Audience.one(audience),
      ).sign(
        SecretKey('openci-workflow-build-number:$key'),
        expiresIn: expires,
        algorithm: algorithm,
      );

  test('rejects expired, timeless, wrong-purpose and malformed claims', () {
    for (final token in [
      signed(expires: const Duration(seconds: -1)),
      signed(expires: null),
      signed(issuer: 'other'),
      signed(audience: 'other'),
      signed(runId: ''),
      signed(algorithm: JWTAlgorithm.HS512),
      '',
      'broken',
    ]) {
      expect(tokens.verify(token), isNull);
    }
  });

  final now = DateTime.utc(2026);
  final job = DriftBuildJob(
    id: 'job',
    teamId: 'team',
    latestRunId: 'run',
    status: BuildJobStatus.IN_PROGRESS,
    owner: 'owner',
    repo: 'repo',
    workflowName: 'CI',
    workflowFileName: 'ci.dart',
    createdAt: now,
    updatedAt: now,
  );
  const env = {'INTERNAL_API_KEY': key};

  test('adds a token only for an active run with referenced secrets', () {
    final variables = workflowEnvironment(
      job: job,
      secretKeys: {'BUILD'},
      environment: env,
    );
    expect(variables.keys, ['OPENCI_WORKFLOW_TOKEN']);
    expectClaims(tokens.verify(variables['OPENCI_WORKFLOW_TOKEN']!));
    expect(
      workflowEnvironment(job: job, secretKeys: {}, environment: env),
      isEmpty,
    );
    expect(
      workflowEnvironment(
        job: job.copyWith(status: BuildJobStatus.SUCCESS),
        secretKeys: {'BUILD'},
        environment: env,
      ),
      isEmpty,
    );
  });

  test('rejects missing signing configuration', () {
    expect(
      () => workflowEnvironment(
        job: job,
        secretKeys: {'BUILD'},
        environment: {},
      ),
      throwsStateError,
    );
  });
}
