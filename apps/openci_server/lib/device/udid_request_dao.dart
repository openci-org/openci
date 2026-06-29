import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/device/udid_request_table.dart';

part 'udid_request_dao.g.dart';

@DriftAccessor(tables: [UdidRequests])
class UdidRequestDao extends DatabaseAccessor<AppDatabase>
    with _$UdidRequestDaoMixin {
  UdidRequestDao(super.attachedDatabase);

  Future<void> createRequest(DriftUdidRequest request) {
    return into(udidRequests).insert(request);
  }

  Future<List<DriftUdidRequest>> getRequestsByTeamId(String teamId) {
    return (select(udidRequests)..where((r) => r.teamId.equals(teamId))).get();
  }

  Future<DriftUdidRequest?> getRequestById(String id) {
    return (select(
      udidRequests,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
  }
}
