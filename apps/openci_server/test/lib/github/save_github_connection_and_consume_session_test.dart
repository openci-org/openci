import 'package:drift/native.dart';
import 'package:openci_server/database.dart';

import '../../helpers/save_github_connection_and_consume_session_tests.dart';

void main() {
  testSaveGitHubConnectionAndConsumeSession(
    () async => AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
      ),
    ),
  );
}
