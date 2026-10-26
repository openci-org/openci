import 'dart:io';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:openci_server/billing/billing_account_table.dart';
import 'package:openci_server/billing/billing_period_table.dart';
import 'package:openci_server/build_job/build_job.dart';
import 'package:openci_server/build_job/build_job_dao.dart';
import 'package:openci_server/build_run/build_run.dart';
import 'package:openci_server/build_run/build_run_dao.dart';
import 'package:openci_server/device/device_dao.dart';
import 'package:openci_server/device/device_table.dart';
import 'package:openci_server/device/udid_request_dao.dart';
import 'package:openci_server/device/udid_request_table.dart';
import 'package:openci_server/github/github_connection_request_table.dart';
import 'package:openci_server/github/github_connection_session_table.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_server/open_postgres_database.dart';
import 'package:openci_server/secret/secret_dao.dart';
import 'package:openci_server/secret/secret_table.dart';
import 'package:openci_server/seed/seed_dao.dart';
import 'package:openci_server/team/invitation_table.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:openci_server/team/team_table.dart';
import 'package:openci_server/webhook_task/skipped_workflow_report_dao.dart';
import 'package:openci_server/webhook_task/skipped_workflow_report_table.dart';
import 'package:openci_server/webhook_task/webhook_task_dao.dart';
import 'package:openci_server/webhook_task/webhook_task_table.dart';
import 'package:openci_shared/openci_shared.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    BuildJobs,
    BuildRuns,
    Teams,
    TeamMembers,
    Secrets,
    WebhookTasks,
    SkippedWorkflowReports,
    UserDevices,
    UdidRequests,
    Invitations,
    GitHubConnectionRequests,
    GitHubConnectionSessions,
    GitHubConnections,
    BillingAccounts,
    BillingPeriods,
  ],
  daos: [
    BuildJobDao,
    BuildRunDao,
    TeamDao,
    WebhookTaskDao,
    SkippedWorkflowReportDao,
    SecretDao,
    DeviceDao,
    UdidRequestDao,
    SeedDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([@visibleForTesting QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 32;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {},
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 17) {
          await m.createTable(invitations);
        }
        if (from < 18) {
          await m.deleteTable('invitations');
        }
        if (from < 19) {
          await m.addColumn(buildJobs, buildJobs.commitMessage);
        }
        if (from < 21) {
          await m.deleteTable('processed_webhooks');
        }
        if (from < 23) {
          await transaction(() async {
            await m.deleteTable('build_step_logs');
            await m.deleteTable('build_steps');
            await m.deleteTable('build_job_logs');
          });
        }
        if (from < 24) {
          await m.deleteTable('worker_heartbeats');
        }
        if (from < 25) {
          await m.dropColumn(teams, 'github_base_url');
        }
        if (from < 26) {
          await m.createTable(gitHubConnectionRequests);
        }
        if (from < 27) {
          await m.createTable(gitHubConnectionSessions);
        }
        if (from < 28) {
          await m.createTable(gitHubConnections);
        }
        if (from < 29) {
          await m.createTable(billingAccounts);
        }
        if (from < 30) {
          await m.createTable(billingPeriods);
        }
        if (from < 31) {
          await m.addColumn(buildRuns, buildRuns.runNumber);
        }
        if (from < 32) {
          await m.createTable(skippedWorkflowReports);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return openPostgresDatabase(loadDatabaseUrl());
  }
}

String loadDatabaseUrl({@visibleForTesting Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  final databaseUrlEnv = env['DATABASE_URL'];

  if (databaseUrlEnv == null || databaseUrlEnv.trim().isEmpty) {
    throw StateError(
      'DATABASE_URL environment variable must be specified.',
    );
  }

  final url = databaseUrlEnv.trim();
  if (!url.contains('sslmode=')) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}sslmode=disable';
  }

  return url;
}
