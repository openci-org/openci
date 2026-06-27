import 'package:drift/drift.dart';
import 'package:openci_server/team/team_table.dart';

@UseRowClass(DriftUserDevice)
class UserDevices extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get teamId =>
      text().references(Teams, #id, onDelete: KeyAction.cascade)();
  TextColumn get udid => text().withLength(min: 25, max: 40)();
  TextColumn get deviceProduct => text().nullable()();
  TextColumn get deviceOsVersion => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DriftUserDevice implements Insertable<DriftUserDevice> {
  final String id;
  final String userId;
  final String teamId;
  final String udid;
  final String? deviceProduct;
  final String? deviceOsVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriftUserDevice({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.udid,
    this.deviceProduct,
    this.deviceOsVersion,
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
      'device_product': Variable<String>(deviceProduct),
      'device_os_version': Variable<String>(deviceOsVersion),
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
      'deviceProduct': deviceProduct,
      'deviceOsVersion': deviceOsVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
