import 'package:test/test.dart';
import 'package:stacked_pr_app/src/models.dart';
import 'package:stacked_pr_app/src/history.dart';
import 'package:mockito/mockito.dart';
import 'package:stacked_pr_app/src/report.dart';
import 'package:stacked_pr_app/src/stack.dart';
import '../support/fixtures.dart';
import '../support/mocks.mocks.dart';

void main() {
  Future<List<PullRequest>> discover(List<PullRequest> pulls) async {
    final api = MockGitHubApi();
    when(api.timeline(any, any, any)).thenAnswer((_) async => []);
    when(api.list(any, any, field: anyNamed('field'))).thenAnswer((i) async {
      final branch = Uri.parse(
        i.positionalArguments[1] as String,
      ).queryParameters['head']?.split(':').last;
      return pulls
          .where((p) => !p.isOpen && p.headRef == branch)
          .map(
            (p) => <String, Object?>{
              'number': p.number,
              'title': p.title,
              'state': p.state,
              'merged': p.merged,
              'head': {
                'ref': p.headRef,
                'sha': p.head,
                'repo': {'id': 20},
              },
              'base': {
                'ref': p.baseRef,
                'sha': p.base,
                'repo': {'id': 20},
              },
            },
          )
          .toList();
    });
    return History(
      api,
      1,
      const Repository(id: 20, fullName: 'org/repo', defaultBranch: 'main'),
    ).discover(pulls);
  }

  test('opening child discovers chain and renders positions', () async {
    final pulls = await discover(chain());
    expect(pulls.map((p) => p.parent), [null, 1, 2]);
    final view = render(pulls, pulls[1]);
    expect(view.body, contains('Stack · 2 / 3'));
    expect(view.body, contains('#1'));
    expect(view.body, contains('#3'));
    expect(view.conclusion, 'action_required');
    expect(render(pulls, pulls[0]).conclusion, 'success');
  });
  test('explicit unrelated retarget detaches edge', () async {
    final now = chain()..[1].baseRef = 'release';
    expect((await discover(now))[1].parent, isNull);
  });
  test('closed unmerged parent is preserved and blocks restack', () async {
    final now = chain();
    now[0] = modify(now[0], {'state': 'closed'});
    final graph = await discover(now);
    expect(graph[1].parent, 1);
    await expectLater(
      planRestack(graph, MockGitRepository()),
      throwsA(isA<RestackException>().having((e) => e.message, 'reason', contains('mergeされず'))),
    );
  });
  test('forks cannot become writable layers', () async {
    final now = chain();
    now[1] = modify(now[1], {'sameRepo': false});
    expect((await discover(now)).map((p) => p.parent), [null, null, null]);
  });
  test('branches are ordered while cycles are rejected', () async {
    final branched = chain()..[2].baseRef = 'db';
    expect((await discover(branched)).map((p) => p.parent), [null, 1, 1]);
    final cycle = chain()..[0].baseRef = 'ui';
    final graph = await discover(cycle);
    expect(() => ordered(graph), throwsA(isA<RestackException>()));
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
