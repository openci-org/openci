import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';

import '../components/dart_code.dart';
import '../components/code_theme_toggle.dart';
import '../components/docs_icon.dart';
import '../components/html.dart';

class DocsHome extends StatelessComponent {
  const DocsHome({super.key});
  @override
  Component build(BuildContext context) => el(
    'div',
    cls: 'd-home',
    children: [
      el(
        'header',
        cls: 'd-home-heading',
        children: [
          el('span', cls: 'd-eyebrow', text: 'LET’S BUILD SOMETHING GENUINE.'),
          el(
            'h1',
            children: [
              Component.text('GenuineCI Docs'),
              el('span', cls: 'd-title-dot', text: '.'),
            ],
          ),
          docLines(
            'p',
            cls: 'd-lead',
            text: 'いつものDartで、ビルドからリリースまで。\nFlutter & DartのためのCIを、ここからはじめましょう。',
          ),
        ],
      ),
      el(
        'section',
        id: 'start',
        cls: 'd-quickstart',
        children: [
          el(
            'div',
            cls: 'd-quickstart-copy',
            children: [
              el('span', cls: 'd-kicker', text: 'YOUR FIRST BUILD'),
              docLines('h2', text: '最初の一歩を、\n一緒に。'),
              docLines('p', text: 'セットアップから、最初のワークフローまで。\n小さなビルドからはじめよう。'),
              el(
                'a',
                cls: 'd-primary',
                attrs: {'href': '/docs/quickstart/'},
                children: [
                  el('span', text: 'クイックスタート'),
                  docsIcon('arrow'),
                ],
              ),
            ],
          ),
          el(
            'div',
            cls: 'd-build-illustration',
            attrs: {'aria-hidden': 'true'},
            children: [
              el(
                'div',
                cls: 'd-illustration-top',
                children: [
                  docsIcon('branch'),
                  el('span', text: 'main'),
                  el('span', cls: 'd-illustration-line'),
                ],
              ),
              el(
                'div',
                cls: 'd-file-card',
                children: [
                  el('span', cls: 'd-file-icon', text: '{ }'),
                  el(
                    'div',
                    children: [
                      el('strong', text: 'flutter_ci.dart'),
                      el('span', text: 'Your workflow. Your code.'),
                    ],
                  ),
                  docsIcon('check'),
                ],
              ),
              el(
                'div',
                cls: 'd-pipeline',
                children: [
                  for (final title in ['Analyze', 'Test', 'Build'])
                    el(
                      'div',
                      children: [
                        el(
                          'span',
                          cls: 'd-pipeline-check',
                          children: [docsIcon('check')],
                        ),
                        el('span', text: title),
                      ],
                    ),
                ],
              ),
              el(
                'div',
                cls: 'd-build-status',
                children: [
                  el('span', cls: 'd-status-dot'),
                  el('span', text: 'ALL CHECKS PASSED'),
                  el('span', text: '↗'),
                ],
              ),
            ],
          ),
        ],
      ),
      el(
        'section',
        id: 'guides',
        cls: 'd-guide-section',
        children: [
          sectionHeading('目的から探す', 'FIND YOUR WAY'),
          el(
            'div',
            cls: 'd-guide-grid',
            children: [
              guide(
                'code',
                'ワークフローを書く',
                'Dartで手順を定義。\n使い慣れた言語をCIにも。',
                '/docs/workflows/',
              ),
              guide(
                'box',
                'Flutterをビルドする',
                '解析、テスト、ビルド。\nアプリの品質をコードで守る。',
                '/docs/flutter/',
              ),
              guide(
                'server',
                '自分のMacで動かす',
                'Apple Siliconで実行。\n実行環境も、自分の手に。',
                '/docs/self-hosting/',
              ),
            ],
          ),
        ],
      ),
      el(
        'section',
        id: 'write-dart',
        cls: 'd-dart-section',
        children: [
          sectionHeading('ワークフローも、いつものDartで。', 'FAMILIAR BY DESIGN'),
          el(
            'p',
            cls: 'd-section-description',
            text: '特別な構文はいりません。関数も、条件分岐も、そのまま。',
          ),
          el(
            'div',
            cls: 'd-home-code d-code-surface',
            attrs: {'data-code-theme': 'dark'},
            children: [
              el(
                'div',
                cls: 'd-code-bar',
                children: [
                  el(
                    'span',
                    children: [
                      docsIcon('code'),
                      Component.text('openci/flutter_ci.dart'),
                    ],
                  ),
                  el('span', cls: 'd-code-language', text: 'Dart'),
                  codeThemeToggle(initialTheme: 'dark'),
                  el(
                    'button',
                    cls: 'd-code-copy',
                    attrs: {
                      'type': 'button',
                      'data-copy-home': '',
                      'aria-label': 'コードをコピー',
                    },
                    children: [
                      docsIcon('copy'),
                      el('span', text: 'コピー'),
                    ],
                  ),
                ],
              ),
              el(
                'pre',
                children: [
                  el(
                    'code',
                    id: 'home-code',
                    children: [
                      RawText(
                        homeWorkflow
                            .split('\n')
                            .map(highlightedDart)
                            .join('\n'),
                      ),
                    ],
                  ),
                ],
              ),
              el(
                'div',
                cls: 'd-code-caption',
                children: [
                  el('span', text: 'シンプルに書いて、確かに動かす。'),
                  link('ワークフローの書き方', '/docs/workflows/', arrow: 'arrow'),
                ],
              ),
            ],
          ),
        ],
      ),
      el(
        'section',
        cls: 'd-reference-section',
        children: [
          el(
            'a',
            cls: 'd-reference-link',
            attrs: {'href': '/docs/cli/'},
            children: [
              docsIcon('terminal'),
              el(
                'div',
                children: [
                  el('strong', text: 'CLIリファレンス'),
                  el('p', text: '必要なコマンドを、すぐ手元に。'),
                ],
              ),
              docsIcon('arrow'),
            ],
          ),
          el(
            'a',
            cls: 'd-reference-link',
            attrs: {'href': '/docs/secrets/'},
            children: [
              docsIcon('lock'),
              el(
                'div',
                children: [
                  el('strong', text: 'シークレットの管理'),
                  el('p', text: 'ビルドに必要な値を管理する。'),
                ],
              ),
              docsIcon('arrow'),
            ],
          ),
        ],
      ),
      el(
        'section',
        id: 'open-source',
        cls: 'd-open-source',
        children: [
          docsIcon('github'),
          el(
            'div',
            children: [
              el('h2', text: 'コードも、つくる過程も、オープンに。'),
              el('p', text: 'GenuineCIはオープンソース。あなたのアイデアを待っています。'),
            ],
          ),
          el(
            'a',
            attrs: {
              'href': 'https://github.com/openci-org/openci',
              'aria-label': 'GitHubでGenuineCIを見る',
            },
            children: [docsIcon('external')],
          ),
        ],
      ),
    ],
  );
}

Component sectionHeading(String title, String label) => el(
  'div',
  cls: 'd-section-heading',
  children: [
    el('h2', text: title),
    el('span', text: label),
  ],
);

Component guide(String icon, String title, String description, String href) =>
    el(
      'a',
      cls: 'd-guide',
      attrs: {'href': href},
      children: [
        el(
          'div',
          cls: 'd-guide-top',
          children: [
            el('span', cls: 'd-guide-icon', children: [docsIcon(icon)]),
            docsIcon('arrow'),
          ],
        ),
        el('h3', text: title),
        docLines('p', text: description),
      ],
    );

const homeWorkflow = '''import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Flutter CI',
    ciTriggers: [CITrigger.push(branch: 'main')],
  );

  await ci.run('flutter pub get');
  await ci.flutter.staticAnalysis();
  await ci.flutter.unitTests();
  await ci.flutter.buildApk();
}''';
