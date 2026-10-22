import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';

class BillingAdmissionStore {
  const BillingAdmissionStore(this.db);

  final AppDatabase db;

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

class BillingAdmissionNotCurrent implements Exception {
  const BillingAdmissionNotCurrent();
}
