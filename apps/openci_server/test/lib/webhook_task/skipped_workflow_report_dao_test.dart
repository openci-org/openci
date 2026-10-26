import 'dart:io';

import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../helpers/skipped_workflow_report_dao_tests.dart';

void main() {
  group('SkippedWorkflowReportDao on SQLite', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('skipped-report-dao-');
      addTearDown(() => directory.delete(recursive: true));
    });

    testSkippedWorkflowReportDao(() async {
      final db = AppDatabase(
        NativeDatabase(
          File('${directory.path}/database.sqlite'),
          setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      addTearDown(db.close);
      return db;
    });
  });
}
