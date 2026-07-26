import 'dart:io';

import 'package:postgres/postgres.dart';

void main() async {
  final databaseUrl =
      Platform.environment['DATABASE_URL'] ??
      'postgres://postgres:your-secure-password-here@localhost:5432/openci?sslmode=disable';

  print('🌱 Connecting to database at $databaseUrl...');

  final conn = await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'openci',
      username: 'postgres',
      password: 'your-secure-password-here',
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.disable,
    ),
  );

  print('🌱 Database connected. Seeding test data...');

  final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final jobId = 'job-local-${DateTime.now().millisecondsSinceEpoch}';

  try {
    // 1. Insert dummy team if not exists
    await conn.execute(
      Sql.named('''
        INSERT INTO teams (id, name, installation_ids, ai_enabled, run_number, created_at, updated_at)
        VALUES ('test-team', 'Test Team', '[]', true, 1, @now, @now)
        ON CONFLICT (id) DO NOTHING;
      '''),
      parameters: {'now': nowEpoch},
    );

    // 2. Insert dummy pending build job
    await conn.execute(
      Sql.named('''
        INSERT INTO build_jobs (
          id,
          team_id,
          status,
          owner,
          repo,
          workflow_name,
          workflow_file_name,
          installation_id,
          runs_on,
          commit_sha,
          commit_message,
          created_at,
          updated_at
        ) VALUES (
          @id,
          'test-team',
          'QUEUED',
          'openci-org',
          'openci',
          'Hello World Pipeline',
          'build.yml',
          '12345678',
          'macos-latest',
          'main',
          'feat: 🎉 Hello World from OpenCI Local Orchard!',
          @now,
          @now
        );
      '''),
      parameters: {
        'id': jobId,
        'now': nowEpoch,
      },
    );

    print('✅ Seed completed successfully!');
    print('   Created Pending BuildJob: $jobId');
  } catch (e, st) {
    print('❌ Error seeding data: $e');
    print(st);
  } finally {
    await conn.close();
  }
}
