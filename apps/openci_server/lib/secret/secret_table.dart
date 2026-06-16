import 'package:drift/drift.dart';
import 'package:openci_server/team/team_table.dart';

@UseRowClass(DriftSecret)
class Secrets extends Table {
  TextColumn get name => text()();
  TextColumn get teamId =>
      text().references(Teams, #id, onDelete: KeyAction.cascade)();
  TextColumn get encryptedValue => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {teamId, name};
}

class DriftSecret implements Insertable<DriftSecret> {
  final String name;
  final String teamId;
  final String encryptedValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriftSecret({
    required this.name,
    required this.teamId,
    required this.encryptedValue,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return {
      'name': Variable<String>(name),
      'team_id': Variable<String>(teamId),
      'encrypted_value': Variable<String>(encryptedValue),
      'created_at': Variable<DateTime>(createdAt),
      'updated_at': Variable<DateTime>(updatedAt),
    };
  }

  @override
  String toString() {
    return 'DriftSecret(name: $name, teamId: $teamId, encryptedValue: [REDACTED], createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'teamId': teamId,
      'encryptedValue': '[REDACTED]',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
