import 'dart:io';

import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'migration from schema 20 adds webhook task scheduling columns',
    () async {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'openci-database-migration-test-',
      );
      final databaseFile = File(p.join(tempDirectory.path, 'database.sqlite'));
      AppDatabase? database;

      try {
        database = AppDatabase(NativeDatabase(databaseFile));
        await database.customStatement('''
        CREATE TABLE IF NOT EXISTS processed_webhooks (
          delivery_id TEXT NOT NULL PRIMARY KEY,
          processed_at INTEGER NOT NULL
        )
      ''');
        final now = DateTime.now().toUtc();
        await database.webhookTaskDao.insertWebhookTask(
          DriftWebhookTask(
            id: 'retained-task',
            deliveryId: 'retained-delivery',
            eventType: 'push',
            payload: '{"ref":"refs/heads/main"}',
            status: 'pending',
            retryCount: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await database.customStatement(
          'ALTER TABLE webhook_tasks DROP COLUMN next_retry_at',
        );
        await database.customStatement(
          'ALTER TABLE webhook_tasks DROP COLUMN lease_until',
        );
        await database.customStatement('PRAGMA user_version = 20');
        await database.close();
        database = null;

        database = AppDatabase(NativeDatabase(databaseFile));
        final processedWebhookTables = await database.customSelect(
          '''
          SELECT name
          FROM sqlite_master
          WHERE type = 'table' AND name = 'processed_webhooks'
        ''',
        ).get();

        expect(processedWebhookTables, isEmpty);
        final retainedTask = await database.webhookTaskDao.getWebhookTask(
          'retained-task',
        );
        expect(retainedTask, isNotNull);
        expect(retainedTask?.leaseUntil, isNull);
        expect(retainedTask?.nextRetryAt, isNull);
      } finally {
        await database?.close();
        tempDirectory.deleteSync(recursive: true);
      }
    },
  );
}
