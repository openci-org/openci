import 'package:drift/drift.dart';
import 'package:genuineci_server/database.dart';
import 'package:genuineci_server/worker_heartbeat/worker_heartbeat_table.dart';

part 'worker_heartbeat_dao.g.dart';

@DriftAccessor(tables: [WorkerHeartbeats])
class WorkerHeartbeatDao extends DatabaseAccessor<AppDatabase>
    with _$WorkerHeartbeatDaoMixin {
  WorkerHeartbeatDao(super.attachedDatabase);

  Future<List<DriftWorkerHeartbeat>> getAllHeartbeats() {
    return (select(
      workerHeartbeats,
    )..orderBy([(t) => OrderingTerm.desc(t.lastSeenAt)])).get();
  }

  Future<void> upsertHeartbeat(DriftWorkerHeartbeat heartbeat) {
    return into(workerHeartbeats).insertOnConflictUpdate(heartbeat);
  }
}
