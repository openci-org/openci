import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:stacked_pr_app/src/models.dart';
import 'package:stacked_pr_app/src/store.dart';
import 'package:stacked_pr_app/src/state_admin.dart';
import '../support/fixtures.dart';

void main() {
  late Directory root;
  late Store store;
  late String path;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('stacked-pr-db-');
    path = p.join(root.path, 'state.sqlite');
    store = Store(path);
  });
  tearDown(() async {
    store.close();
    await root.delete(recursive: true);
  });
  test('restart retains boundaries, journal and running jobs with old JSON format', () {
    expect(store.enqueue('delivery', 'push', {'ref': 'refs/heads/child'}), isTrue);
    expect(store.enqueue('delivery', 'push', {}), isFalse);
    store.next();
    // Write plain JSON in the original schema, independent of the Dart serializers.
    final legacyState = {
      'pulls': [
        {
          'number': 2,
          'title': 'Child',
          'url': '',
          'state': 'open',
          'merged': false,
          'draft': false,
          'sameRepo': true,
          'head': 'b' * 40,
          'headRef': 'child',
          'base': 'a' * 40,
          'baseRef': 'parent',
          'parent': 1,
          'boundary': 'a' * 40,
        },
      ],
    };
    final legacyOperation = {
      'phase': 'prepared',
      'nextState': legacyState,
      'changes': [
        {
          'number': 2,
          'headRef': 'child',
          'oldHead': 'b' * 40,
          'newHead': 'c' * 40,
          'oldBase': 'parent',
          'newBase': 'main',
        },
      ],
    };
    store.db.execute('INSERT INTO repositories(id,state,operation) VALUES(?,?,?)', [
      '12:34',
      jsonEncode(legacyState),
      jsonEncode(legacyOperation),
    ]);
    store.close();
    store = Store(path);
    expect(store.load('12:34').state.toJson(), legacyState);
    expect(store.load('12:34').operation!.toJson(), legacyOperation);
    final job = store.next()!;
    expect(job.id, 'delivery');
    expect(job.attempts, 2);
    store.done(job.id);
    expect(store.next(), isNull);
    expect(store.enqueue('delivery', 'push', {}), isFalse);
  });
  test('six failures stop retrying; admin can retry without resetting boundaries', () {
    store.enqueue('failed', 'push', {});
    for (var i = 0; i < 6; i++) {
      final job = store.next()!;
      store.fail(job, 'safe failure');
      store.db.execute('UPDATE jobs SET available=0');
    }
    expect(store.next(), isNull);
    expect(manageState(path, 'retry-failed'), {'retried': 1});
    expect(store.next()!.attempts, 1);
  });
  test('discard operation retains saved parent boundary', () {
    final state = RepositoryState(chain());
    store.save('12:34', state, Operation(changes: [], nextState: state));
    expect(manageState(path, 'status')['operations'], hasLength(1));
    expect(manageState(path, 'discard-operation', '12:34')['discarded'], 1);
    expect(store.load('12:34').operation, isNull);
    expect(store.load('12:34').state.pulls[1].boundary, 'a' * 40);
  });
  test('installation removal stops polling targets', () {
    store.remember(10, const Repository(id: 20, fullName: 'org/repo'));
    store.remember(10, const Repository(id: 21, fullName: 'org/other'));
    store.forget(10, 20);
    expect(store.targets().single.repo.id, 21);
    store.forget(10);
    expect(store.targets(), isEmpty);
  });
  test('closed reports recover legacy state and survive restart until acknowledged', () {
    final pulls = [
      modify(chain()[0], {'state': 'closed', 'merged': true}),
    ];
    store.save('12:34', RepositoryState(pulls));
    expect(store.pendingClosedReports('12:34', store.load('12:34').state.pulls), [1]);
    store.close();
    store = Store(path);
    expect(store.pendingClosedReports('12:34', pulls), [1]);
    store.completeClosedReports('12:34', [1]);
    // Replacing a repository snapshot must not undo the report acknowledgement.
    store.save('12:34', RepositoryState(pulls));
    store.close();
    store = Store(path);
    expect(store.pendingClosedReports('12:34', pulls), isEmpty);
    expect(store.pendingClosedReports('56:78', pulls), [1]);
    expect(store.pendingClosedReports('12:34', [chain()[0]]), isEmpty);
    expect(store.pendingClosedReports('12:34', pulls), [1]);
  });
}
