import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('WorkerHeartbeatDao', () {
    test('Can insert, get, and update heartbeats', () async {
      final now = DateTime.now().toUtc();
      final heartbeat = DriftWorkerHeartbeat(
        id: 'worker-1',
        version: '1.0.0',
        platform: 'macos',
        status: 'idle',
        lastSeenAt: now,
      );

      await db.workerHeartbeatDao.upsertHeartbeat(heartbeat);

      // Get all heartbeats
      final list = await db.workerHeartbeatDao.getAllHeartbeats();
      expect(list, hasLength(1));
      expect(list.first.id, 'worker-1');
      expect(list.first.version, '1.0.0');
      expect(list.first.platform, 'macos');
      expect(list.first.status, 'idle');
      expect(
        list.first.lastSeenAt.difference(now).inSeconds.abs(),
        lessThan(2),
      );

      // Update on conflict
      final updatedNow = DateTime.now().toUtc().add(
        const Duration(seconds: 10),
      );
      final updatedHeartbeat = DriftWorkerHeartbeat(
        id: 'worker-1',
        version: '1.0.1',
        platform: 'linux',
        status: 'busy',
        lastSeenAt: updatedNow,
      );

      await db.workerHeartbeatDao.upsertHeartbeat(updatedHeartbeat);

      final updatedList = await db.workerHeartbeatDao.getAllHeartbeats();
      expect(updatedList, hasLength(1));
      expect(updatedList.first.version, '1.0.1');
      expect(updatedList.first.platform, 'linux');
      expect(updatedList.first.status, 'busy');
      expect(
        updatedList.first.lastSeenAt.difference(updatedNow).inSeconds.abs(),
        lessThan(2),
      );
    });
  });
}
