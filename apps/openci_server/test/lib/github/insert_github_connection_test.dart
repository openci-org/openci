import 'package:drift/native.dart';
import 'package:openci_server/database.dart';

import '../../helpers/insert_github_connection_tests.dart';

void main() {
  testInsertGitHubConnection(
    () async => AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    ),
  );
}
