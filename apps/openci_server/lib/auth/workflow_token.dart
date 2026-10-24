import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';

typedef WorkflowTokenClaims = ({
  String jobId,
  String runId,
  String teamId,
  Set<String> secretKeys,
});

class WorkflowToken {
  WorkflowToken(String signingKey)
    : _key = SecretKey('openci-workflow-build-number:$signingKey') {
    if (signingKey.isEmpty) {
      throw StateError('Workflow signing key is missing.');
    }
  }

  final SecretKey _key;
  static const _issuer = 'openci-workflow';
  static final _audience = Audience.one('build-number');

  String issue(WorkflowTokenClaims claims) => JWT(
    {
      'jobId': claims.jobId,
      'runId': claims.runId,
      'teamId': claims.teamId,
      'secretKeys': claims.secretKeys.toList(),
    },
    issuer: _issuer,
    audience: _audience,
  ).sign(_key, expiresIn: const Duration(hours: 24));

  WorkflowTokenClaims? verify(String token) {
    try {
      final jwt = JWT.verify(
        token,
        _key,
        issuer: _issuer,
        audience: _audience,
      );
      if (jwt.header?['alg'] != 'HS256') return null;
      final payload = jwt.payload;
      if (payload is! Map<String, dynamic> || payload['exp'] is! num) {
        return null;
      }
      final jobId = payload['jobId'];
      final runId = payload['runId'];
      final teamId = payload['teamId'];
      final keys = payload['secretKeys'];
      if (jobId is! String ||
          jobId.isEmpty ||
          runId is! String ||
          runId.isEmpty ||
          teamId is! String ||
          teamId.isEmpty ||
          keys is! List ||
          keys.any((key) => key is! String)) {
        return null;
      }
      return (
        jobId: jobId,
        runId: runId,
        teamId: teamId,
        secretKeys: keys.cast<String>().toSet(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Creates credentials limited to the active run and its referenced secrets.
Map<String, String> workflowEnvironment({
  required DriftBuildJob job,
  required Set<String> secretKeys,
  required Map<String, String> environment,
}) {
  if (secretKeys.isEmpty ||
      job.status != BuildJobStatus.IN_PROGRESS ||
      job.latestRunId == null ||
      job.teamId == null) {
    return {};
  }
  final token = WorkflowToken(environment['INTERNAL_API_KEY'] ?? '').issue((
    jobId: job.id,
    runId: job.latestRunId!,
    teamId: job.teamId!,
    secretKeys: secretKeys,
  ));
  return {'OPENCI_WORKFLOW_TOKEN': token};
}
