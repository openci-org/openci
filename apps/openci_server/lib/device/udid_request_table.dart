import 'package:drift/drift.dart';
import 'package:openci_server/team/team_table.dart';

@UseRowClass(DriftUdidRequest)
class UdidRequests extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get teamId =>
      text().references(Teams, #id, onDelete: KeyAction.cascade)();
  TextColumn get udid => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DriftUdidRequest implements Insertable<DriftUdidRequest> {
  final String id;
  final String userId;
  final String teamId;
  final String udid;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriftUdidRequest({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.udid,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return {
      'id': Variable<String>(id),
      'user_id': Variable<String>(userId),
      'team_id': Variable<String>(teamId),
      'udid': Variable<String>(udid),
      'created_at': Variable<DateTime>(createdAt),
      'updated_at': Variable<DateTime>(updatedAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'teamId': teamId,
      'udid': udid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
