import 'dart:convert';
import 'dart:math' as math;
import 'package:sqlite3/sqlite3.dart';
import 'models.dart';

class Store {
  Store(String path) : db = sqlite3.open(path) {
    db.execute('''
      PRAGMA journal_mode=WAL;
      PRAGMA synchronous=FULL;
      PRAGMA busy_timeout=5000;
      CREATE TABLE IF NOT EXISTS jobs (
        id TEXT PRIMARY KEY, event TEXT NOT NULL, payload TEXT NOT NULL,
        state TEXT NOT NULL DEFAULT 'pending', attempts INTEGER NOT NULL DEFAULT 0,
        available INTEGER NOT NULL, created INTEGER NOT NULL, error TEXT
      );
      CREATE INDEX IF NOT EXISTS jobs_ready ON jobs(state, available);
      CREATE TABLE IF NOT EXISTS repositories (
        id TEXT PRIMARY KEY, state TEXT NOT NULL, operation TEXT
      );
      CREATE TABLE IF NOT EXISTS targets (
        id TEXT PRIMARY KEY, installation INTEGER NOT NULL, repo TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS closed_reports (
        repository TEXT NOT NULL, number INTEGER NOT NULL,
        reported INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(repository, number)
      );
      UPDATE jobs SET state='pending' WHERE state='running';
    ''');
  }
  final Database db;
  int get _now => DateTime.now().millisecondsSinceEpoch;

  bool enqueue(String id, String event, Json payload) {
    db.execute('INSERT OR IGNORE INTO jobs(id,event,payload,available,created) VALUES(?,?,?,?,?)', [
      id,
      event,
      jsonEncode(payload),
      _now,
      _now,
    ]);
    return db.updatedRows > 0;
  }

  Job? next() {
    final rows = db.select(
      '''SELECT * FROM jobs WHERE state='pending' AND available<=?
      ORDER BY created,rowid LIMIT 1''',
      [_now],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    db.execute("UPDATE jobs SET state='running',attempts=attempts+1 WHERE id=?", [row['id']]);
    return Job(
      id: row['id'] as String,
      event: row['event'] as String,
      payload: jsonObject(jsonDecode(row['payload'] as String)),
      attempts: (row['attempts'] as int) + 1,
    );
  }

  void done(String id) =>
      db.execute("UPDATE jobs SET state='done',payload='{}',error=NULL WHERE id=?", [id]);
  void fail(Job job, String error) =>
      db.execute('UPDATE jobs SET state=?,available=?,error=? WHERE id=?', [
        job.attempts >= 6 ? 'failed' : 'pending',
        _now + math.min(300000, 5000 * math.pow(2, job.attempts).toInt()),
        error,
        job.id,
      ]);
  SavedRepository load(String id) {
    final rows = db.select('SELECT * FROM repositories WHERE id=?', [id]);
    if (rows.isEmpty) return SavedRepository(RepositoryState(), null);
    final row = rows.single;
    return SavedRepository(
      RepositoryState.fromJson(jsonObject(jsonDecode(row['state'] as String))),
      row['operation'] == null
          ? null
          : Operation.fromJson(jsonObject(jsonDecode(row['operation'] as String))),
    );
  }

  void save(String id, RepositoryState state, [Operation? operation]) => db.execute(
    '''
    INSERT INTO repositories(id,state,operation) VALUES(?,?,?)
    ON CONFLICT(id) DO UPDATE SET state=excluded.state,operation=excluded.operation
  ''',
    [id, jsonEncode(state.toJson()), operation == null ? null : jsonEncode(operation.toJson())],
  );

  List<int> pendingClosedReports(String id, List<PullRequest> pulls) {
    final closed = <int>{};
    for (final pr in pulls) {
      if (pr.isOpen) {
        db.execute('DELETE FROM closed_reports WHERE repository=? AND number=?', [id, pr.number]);
      } else if (pr.sameRepo) {
        closed.add(pr.number);
        // Also discover unreported closed PRs saved by older app versions.
        db.execute('INSERT OR IGNORE INTO closed_reports(repository,number) VALUES(?,?)', [
          id,
          pr.number,
        ]);
      }
    }
    return db
        .select('SELECT number FROM closed_reports WHERE repository=? AND reported=0', [id])
        .map((row) => row['number'] as int)
        .where(closed.contains)
        .toList();
  }

  void completeClosedReports(String id, List<int> numbers) {
    for (final number in numbers) {
      db.execute('UPDATE closed_reports SET reported=1 WHERE repository=? AND number=?', [
        id,
        number,
      ]);
    }
  }

  void remember(int installation, Repository repo) => db.execute(
    '''
    INSERT INTO targets(id,installation,repo) VALUES(?,?,?)
    ON CONFLICT(id) DO UPDATE SET repo=excluded.repo
  ''',
    ['$installation:${repo.id}', installation, jsonEncode(repo.toJson())],
  );
  List<({int installation, Repository repo})> targets() => db
      .select('SELECT * FROM targets')
      .map(
        (r) => (
          installation: r['installation'] as int,
          repo: Repository.fromJson(jsonObject(jsonDecode(r['repo'] as String))),
        ),
      )
      .toList();
  void forget(int installation, [int? repository]) {
    if (repository == null) {
      db.execute('DELETE FROM targets WHERE installation=?', [installation]);
    } else {
      db.execute('DELETE FROM targets WHERE id=?', ['$installation:$repository']);
    }
  }

  void prune() => db.execute("DELETE FROM jobs WHERE state='done' AND created<?", [
    _now - const Duration(days: 30).inMilliseconds,
  ]);
  void close() => db.close();
}
