import 'package:drift/native.dart';
import 'package:openci_server/database.dart';

import '../../helpers/get_team_by_installation_id_tests.dart';

void main() {
  testGetTeamByInstallationId(
    () async => AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    ),
  );
}
