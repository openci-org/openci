import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';

class BillingAdmissionStore {
  const BillingAdmissionStore(this.db);

  final AppDatabase db;

  Future<T> withCurrentAttempt<T>(
    BillingWorkerAttempt attempt,
    BuildJobStatus outcome,
    Future<T> Function(DriftBuildJob) action,
  ) => db.transaction(() async {
    if (!{
      BuildJobStatus.SUCCESS,
      BuildJobStatus.FAILURE,
      BuildJobStatus.CANCELLED,
      BuildJobStatus.TIMED_OUT,
    }.contains(outcome)) {
      throw ArgumentError.value(outcome, 'outcome');
    }
    await db
        .customSelect(
          r'SELECT id FROM build_jobs WHERE id = $1 FOR UPDATE',
          variables: [Variable.withString(attempt.jobId)],
        )
        .get();
    final job = await db.buildJobDao.getBuildJob(attempt.jobId);
    if (job == null ||
        job.workerHost != attempt.workerHost ||
        (job.status != BuildJobStatus.IN_PROGRESS && job.status != outcome)) {
      throw const BillingAdmissionNotCurrent();
    }
    final admission = await db
        .customSelect(
          r'''SELECT run_id, closed_at_ms FROM billing_admissions
        WHERE id = $1 AND job_id = $2 AND worker_host = $3 AND team_id = $4''',
          variables: [
            Variable.withString(attempt.admissionId),
            Variable.withString(attempt.jobId),
            Variable.withString(attempt.workerHost),
            Variable.withString(job.teamId ?? ''),
          ],
        )
        .getSingleOrNull();
    if (admission == null) throw const BillingAdmissionNotCurrent();
    final runId = admission.readNullable<String>('run_id');
    final bound = runId == attempt.runId && job.latestRunId == attempt.runId;
    final unboundFailure =
        outcome == BuildJobStatus.FAILURE &&
        job.status == BuildJobStatus.IN_PROGRESS &&
        job.latestRunId == null &&
        runId == null &&
        admission.readNullable<int>('closed_at_ms') == null;
    if (!bound && !unboundFailure) throw const BillingAdmissionNotCurrent();
    return action(job);
  });

  Future<void> completeJob(
    BillingWorkerAttempt attempt,
    BuildJobStatus outcome,
  ) => withCurrentAttempt(attempt, outcome, (_) async {
    final now = DateTime.now().toUtc();
    await (db.update(
      db.buildJobs,
    )..where((job) => job.id.equals(attempt.jobId))).write(
      BuildJobsCompanion(
        status: Value(outcome),
        completedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await db.customUpdate(
      r'''UPDATE billing_admissions SET closed_at_ms = GREATEST(claimed_at_ms, $1)
            WHERE id = $2 AND closed_at_ms IS NULL''',
      variables: [
        Variable.withInt(now.millisecondsSinceEpoch),
        Variable.withString(attempt.admissionId),
      ],
    );
  });

  Future<void> bindRun({
    required String admissionId,
    required String jobId,
    required String runId,
    required String workerHost,
  }) => db.transaction(() async {
    final job = await db
        .customSelect(
          r'''SELECT id FROM build_jobs WHERE id = $1 AND worker_host = $2
        AND status = 'IN_PROGRESS' AND latest_run_id IS NULL FOR UPDATE''',
          variables: [
            Variable.withString(jobId),
            Variable.withString(workerHost),
          ],
        )
        .getSingleOrNull();
    if (job == null) throw const BillingAdmissionNotCurrent();
    final updated = await db.customUpdate(
      r'''UPDATE billing_admissions SET run_id = $1
        WHERE id = $2 AND job_id = $3 AND worker_host = $4
          AND team_id = (SELECT team_id FROM build_jobs WHERE id = $3)
          AND run_id IS NULL AND closed_at_ms IS NULL AND start_by_ms > $5''',
      variables: [
        Variable.withString(runId),
        Variable.withString(admissionId),
        Variable.withString(jobId),
        Variable.withString(workerHost),
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
      ],
    );
    if (updated != 1) throw const BillingAdmissionNotCurrent();
  });
}

class BillingWorkerAttempt {
  const BillingWorkerAttempt({
    required this.admissionId,
    required this.jobId,
    required this.runId,
    required this.workerHost,
  });

  factory BillingWorkerAttempt.fromJson(
    String jobId,
    Map<String, dynamic> payload,
  ) {
    String field(String key) {
      final value = payload[key];
      if (value is! String || value.trim().isEmpty || value.length > 255) {
        throw const FormatException('billing_attempt_required');
      }
      return value;
    }

    return BillingWorkerAttempt(
      admissionId: field('billingAdmissionId'),
      jobId: jobId,
      runId: field('runId'),
      workerHost: field('workerHost'),
    );
  }

  final String admissionId;
  final String jobId;
  final String runId;
  final String workerHost;
}

class BillingAdmissionNotCurrent implements Exception {
  const BillingAdmissionNotCurrent();
}
