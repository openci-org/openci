import 'package:drift/drift.dart';
import 'package:genuineci_server/team/team_table.dart';

enum InvitationStatus {
  pending,
  accepted,
  expired,
}

class Invitations extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get teamId =>
      text().references(Teams, #id, onDelete: KeyAction.cascade)();
  TextColumn get token => text().unique()();
  TextColumn get status => textEnum<InvitationStatus>()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
