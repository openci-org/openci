import 'package:drift/native.dart';
import 'package:openci_server/database.dart';

import '../../helpers/read_active_github_connections_tests.dart';

void main() {
  testReadActiveGitHubConnections(
    () async => AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    ),
  );
}
