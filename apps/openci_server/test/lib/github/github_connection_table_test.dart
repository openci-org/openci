import 'package:drift/native.dart';
import 'package:openci_server/database.dart';

import '../../helpers/github_connection_table_tests.dart';

void main() {
  testGitHubConnectionTable(
    () async => AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    ),
  );
}
