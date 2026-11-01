import 'package:test/test.dart';
import 'package:stacked_pr_app/src/models.dart';
import 'package:stacked_pr_app/src/report.dart';
import 'package:stacked_pr_app/src/stack.dart';
import '../support/fixtures.dart';
import '../support/mocks.mocks.dart';

void main() {
  test('opening child discovers chain and renders positions', () {
    final pulls = connect(chain(), []);
    expect(pulls.map((p) => p.parent), [null, 1, 2]);
    final view = render(pulls, pulls[1]);
    expect(view.body, contains('Stack · 2 / 3'));
    expect(view.body, contains('#1'));
    expect(view.body, contains('#3'));
    expect(view.conclusion, 'action_required');
    expect(render(pulls, pulls[0]).conclusion, 'success');
  });
  test('explicit unrelated retarget detaches edge', () {
    final now = chain()..[1].baseRef = 'release';
    expect(connect(now, chain())[1].parent, isNull);
  });
  test('closed unmerged parent is preserved and blocks restack', () async {
    final now = chain();
    now[0] = modify(now[0], {'state': 'closed'});
    final graph = connect(now, chain());
    expect(graph[1].parent, 1);
    await expectLater(
      planRestack(graph, MockGitRepository()),
      throwsA(isA<RestackException>().having((e) => e.message, 'reason', contains('mergeされず'))),
    );
  });
  test('forks cannot become writable layers', () {
    final now = chain();
    now[1] = modify(now[1], {'sameRepo': false});
    expect(connect(now, []).map((p) => p.parent), [null, null, null]);
  });
  test('ambiguous parents, branching and cycles are rejected', () {
    final ambiguous = chain();
    ambiguous.add(modify(ambiguous[0], {'number': 4}));
    expect(() => connect(ambiguous, []), throwsA(isA<RestackException>()));
    final branched = chain()..[2].baseRef = 'db';
    expect(() => connect(branched, []), throwsA(isA<RestackException>()));
    final cycle = chain()..[0].baseRef = 'ui';
    expect(() => connect(cycle, []), throwsA(isA<RestackException>()));
  });
  test('titles cannot break Markdown tables or mention users', () {
    final pulls = chain();
    pulls[1] = modify(pulls[1], {'title': '@everyone | <script>\nhello *bold*'});
    final body = render(pulls, pulls[1]).body;
    expect(body, isNot(contains('@everyone')));
    expect(body, isNot(contains('<script>')));
    expect(body, contains('&#124;'));
    expect(body, contains(r'\*bold\*'));
  });
  test('topological order does not depend on API order', () {
    expect(ordered(chain().reversed.toList()).map((p) => p.number), [1, 2, 3]);
  });
}
