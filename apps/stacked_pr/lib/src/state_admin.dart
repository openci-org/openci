import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import 'models.dart';

Json manageState(String path, String command, [String? repositoryId]) {
  if (!['status', 'retry-failed', 'discard-operation'].contains(command)) {
    throw const FormatException(
      'Usage: state status|retry-failed|discard-operation INSTALLATION_ID:REPO_ID',
    );
  }
  final db = sqlite3.open(path, mode: command == 'status' ? OpenMode.readOnly : OpenMode.readWrite);
  try {
    db.execute('PRAGMA busy_timeout=5000');
    if (command == 'status') {
      return {
        'jobs': db
            .select('SELECT state,COUNT(*) AS count FROM jobs GROUP BY state')
            .map((row) => Map<String, Object?>.from(row))
            .toList(),
        'operations': db
            .select('SELECT id,operation FROM repositories WHERE operation IS NOT NULL')
            .map(
              (row) => <String, Object?>{
                'id': row['id'],
                ...jsonObject(jsonDecode(row['operation'] as String)),
              }..remove('nextState'),
            )
            .toList(),
      };
    }
    if (command == 'retry-failed') {
      db.execute("UPDATE jobs SET state='pending',attempts=0,available=? WHERE state='failed'", [
        DateTime.now().millisecondsSinceEpoch,
      ]);
      return {'retried': db.updatedRows};
    }
    if (repositoryId == null || !RegExp(r'^\d+:\d+$').hasMatch(repositoryId)) {
      throw const FormatException('Specify INSTALLATION_ID:REPO_ID from status');
    }
    db.execute('UPDATE repositories SET operation=NULL WHERE id=? AND operation IS NOT NULL', [
      repositoryId,
    ]);
    return {'discarded': db.updatedRows, 'repositoryId': repositoryId};
  } finally {
    db.close();
  }
}
