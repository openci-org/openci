import 'package:drift/native.dart';
import 'package:genuineci_server/build_job/build_step_log_dao.dart';
import 'package:genuineci_server/database.dart';
import 'package:test/test.dart';

void main() {
  group('BuildStepLogDao', () {
    late AppDatabase db;
    late BuildStepLogDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.buildStepLogDao;
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'step logs preserve insertion order and stay within their step',
      () async {
        await dao.insertBuildStepLog('step-a', 'first');
        await dao.insertBuildStepLog('step-b', 'unrelated');
        await dao.insertBuildStepLog('step-a', 'second');

        expect(
          (await dao.getBuildStepLogs('step-a')).map((log) => log.logContent),
          ['first', 'second'],
        );
        expect(await dao.getBuildStepLogs('missing'), isEmpty);
      },
    );
  });
}
