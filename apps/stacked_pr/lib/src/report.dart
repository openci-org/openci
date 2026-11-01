import 'github.dart';
import 'models.dart';
import 'stack.dart';

const marker = '<!-- stacked-pr-app:stack -->';
const _code = '\u0060';
String escapeText(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('|', '&#124;')
    .replaceAll('@', '&#64;')
    .replaceAll(RegExp(r'[\r\n]+'), ' ')
    .replaceAllMapped(RegExp(r'[\\\x60*_\[\]]'), (m) => '\\${m[0]}');

class StackView {
  const StackView({
    required this.body,
    required this.title,
    required this.conclusion,
    required this.connected,
  });
  final String body, title, conclusion;
  final bool connected;
}

StackView render(
  List<PullRequest> pulls,
  PullRequest pr, {
  RestackException? error,
  bool observeOnly = false,
}) {
  List<PullRequest> stack;
  try {
    stack = stackFor(pulls, pr.number);
  } on RestackException {
    stack = pulls;
  }
  final active = stack.where((p) => p.isOpen).toList();
  final position = active.indexWhere((p) => p.number == pr.number) + 1;
  final title = pr.isOpen ? 'Stack · $position / ${active.length}' : 'Stack · closed';
  final lines = [marker, '## $title', '', '| PR | 依存先 | 内容 | 状態 |', '| --- | --- | --- | --- |'];
  for (final item in stack) {
    final current = item.number == pr.number;
    final status = item.merged
        ? 'Merged'
        : !item.isOpen
        ? 'Closed'
        : item.draft
        ? 'Draft'
        : 'Open';
    lines.add(
      '| ${current ? '**→ ' : ''}#${item.number}${current ? '**' : ''} | ${item.parent == null ? '—' : '#${item.parent}'} | ${escapeText(item.title)} | $status |',
    );
  }
  final parent = pulls.where((p) => p.number == pr.parent && p.isOpen).firstOrNull;
  var conclusion = parent == null ? 'success' : 'action_required';
  if (error != null &&
      (error.number == null || stack.any((member) => member.number == error.number))) {
    conclusion = 'failure';
    lines.addAll([
      '',
      '**Restack停止${error.number == null ? '' : ' · #${error.number}'}：${escapeText(error.message)}**',
    ]);
    if (error.files.isNotEmpty) {
      lines.addAll(['', '競合ファイル：', ...error.files.take(30).map((f) => '- ${escapeText(f)}')]);
    }
    lines.addAll(['', '履歴または設定を修正してから $_code/stack sync$_code を実行してください。']);
  } else {
    lines.addAll([
      '',
      parent == null ? '依存する未mergeの親PRはありません。' : '依存先：#${parent.number}。親PRを先にmergeしてください。',
      '',
      observeOnly
          ? '観察モード：自動rebaseは無効です。$_code/stack sync$_code で実行できます。'
          : '親の更新・merge後は、子PR固有の変更を自動でrebaseします。',
    ]);
  }
  lines.addAll([
    '',
    '$_code/stack sync$_code：状態を再確認し、必要なrebaseを実行',
    '',
    '自動更新後は ${_code}git fetch origin$_code で最新の履歴を取得してください。ローカル変更がある場合の同期方法は、このAppのREADMEを参照してください。',
  ]);
  return StackView(
    body: lines.join('\n'),
    title: title,
    conclusion: conclusion,
    connected: stack.length > 1,
  );
}

Json _object(Object? value) => value is Map ? jsonObject(value) : {};

class Reporter {
  Reporter(this.api);
  final GitHubApi api;

  Future<void> publish(
    int installation,
    Repository repo,
    List<PullRequest> pulls, {
    RestackException? error,
    bool observeOnly = false,
    List<int> closedToUpdate = const [],
  }) async {
    final app = await api.identity();
    final path = repo.apiPath;
    for (final pr in pulls) {
      if (!pr.sameRepo || (!pr.isOpen && !closedToUpdate.contains(pr.number))) continue;
      final view = render(pulls, pr, error: error, observeOnly: observeOnly);
      final comments = await api.list(installation, '$path/issues/${pr.number}/comments');
      final existing = comments
          .where(
            (c) =>
                (c['body'] as String? ?? '').startsWith(marker) &&
                (_object(c['performed_via_github_app'])['id'] == app['id'] ||
                    (_object(c['user'])['type'] == 'Bot' &&
                        _object(c['user'])['login'] == '${app['slug']}[bot]')),
          )
          .firstOrNull;
      if (!view.connected && existing == null && view.conclusion != 'failure') continue;
      if (existing == null) {
        await api.request(installation, 'POST', '$path/issues/${pr.number}/comments', {
          'body': view.body,
        });
      } else if (existing['body'] != view.body) {
        await api.request(installation, 'PATCH', '$path/issues/comments/${existing['id']}', {
          'body': view.body,
        });
      }
      if (!pr.isOpen) continue;
      final externalId = 'stacked-pr:${repo.id}:${pr.number}';
      final checks = await api.list(
        installation,
        '$path/commits/${pr.head}/check-runs?filter=all',
        field: 'check_runs',
      );
      final check = checks
          .where((c) => _object(c['app'])['id'] == app['id'] && c['external_id'] == externalId)
          .firstOrNull;
      final output = {'title': view.title, 'summary': view.body};
      final actions = [
        {
          'label': 'Sync',
          'description': 'Synchronize dependent pull requests',
          // Keep the identifier stable so actions on existing checks still work.
          'identifier': 'restack',
        },
      ];
      final body = <String, Object?>{
        'status': 'completed',
        'conclusion': view.conclusion,
        'output': output,
        'actions': actions,
      };
      if (check == null) {
        await api.request(installation, 'POST', '$path/check-runs', {
          ...body,
          'name': 'Stacked PR',
          'head_sha': pr.head,
          'external_id': externalId,
        });
      } else if (check['conclusion'] != view.conclusion ||
          _object(check['output'])['summary'] != view.body) {
        await api.request(installation, 'PATCH', '$path/check-runs/${check['id']}', body);
      }
    }
  }
}
