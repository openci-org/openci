import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';

import '../components/code_theme_toggle.dart';
import '../components/dart_code.dart';
import '../components/docs_icon.dart';
import '../components/html.dart';
import '../l10n/localized_component.dart';

class DocsHome extends LocalizedComponent {
  const DocsHome(super.locale, {super.key});
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
            text: t(
              'いつものDartで、ビルドからリリースまで。\nFlutter & DartのためのCIを、ここからはじめましょう。',
              'From build to release, in the Dart you know.\nStart here with CI for Flutter & Dart.',
            ),
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
              docLines(
                'h2',
                text: t('最初の一歩を、\n一緒に。', 'Your first steps.\nTogether.'),
              ),
              docLines(
                'p',
                text: t(
                  'セットアップから、最初のワークフローまで。\n小さなビルドからはじめよう。',
                  'From setup to your first workflow.\nStart with a small build.',
                ),
              ),
              el(
                'a',
                cls: 'd-primary',
                attrs: {'href': localPath('/docs/quickstart/')},
                children: [
                  el('span', text: t('クイックスタート', 'Quickstart')),
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
          sectionHeading(t('目的から探す', 'Find a guide'), 'FIND YOUR WAY'),
          el(
            'div',
            cls: 'd-guide-grid',
            children: [
              guide(
                'code',
                t('ワークフローを書く', 'Write a workflow'),
                t(
                  'Dartで手順を定義。\n使い慣れた言語をCIにも。',
                  'Define your steps in Dart.\nA familiar language for your CI.',
                ),
                localPath('/docs/workflows/'),
              ),
              guide(
                'box',
                t('Flutterをビルドする', 'Build with Flutter'),
                t(
                  '解析、テスト、ビルド。\nアプリの品質をコードで守る。',
                  'Analyze, test, and build.\nKeep your app quality in code.',
                ),
                localPath('/docs/flutter/'),
              ),
              guide(
                'server',
                t('自分のMacで動かす', 'Run on your own Mac'),
                t(
                  'Apple Siliconで実行。\n実行環境も、自分の手に。',
                  'Run on Apple Silicon.\nOwn your build environment.',
                ),
                localPath('/docs/self-hosting/'),
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
          sectionHeading(
            t('ワークフローも、いつものDartで。', 'Workflows in the Dart you know.'),
            'FAMILIAR BY DESIGN',
          ),
          el(
            'p',
            cls: 'd-section-description',
            text: t(
              '特別な構文はいりません。関数も、条件分岐も、そのまま。',
              'No special syntax. Use the same functions and conditionals you already know.',
            ),
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
                  codeThemeToggle(locale: locale, initialTheme: 'dark'),
                  el(
                    'button',
                    cls: 'd-code-copy',
                    attrs: {
                      'type': 'button',
                      'data-copy-home': '',
                      'aria-label': t('コードをコピー', 'Copy code'),
                    },
                    children: [
                      docsIcon('copy'),
                      el('span', text: t('コピー', 'Copy')),
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
                  el(
                    'span',
                    text: t(
                      'シンプルに書いて、確かに動かす。',
                      'Simple code. Reliable builds.',
                    ),
                  ),
                  link(
                    t('ワークフローの書き方', 'Writing workflows'),
                    localPath('/docs/workflows/'),
                    arrow: 'arrow',
                  ),
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
            attrs: {'href': localPath('/docs/cli/')},
            children: [
              docsIcon('terminal'),
              el(
                'div',
                children: [
                  el('strong', text: t('CLIリファレンス', 'CLI reference')),
                  el(
                    'p',
                    text: t(
                      '必要なコマンドを、すぐ手元に。',
                      'The commands you need, close at hand.',
                    ),
                  ),
                ],
              ),
              docsIcon('arrow'),
            ],
          ),
          el(
            'a',
            cls: 'd-reference-link',
            attrs: {'href': localPath('/docs/secrets/')},
            children: [
              docsIcon('lock'),
              el(
                'div',
                children: [
                  el('strong', text: t('シークレットの管理', 'Manage secrets')),
                  el(
                    'p',
                    text: t(
                      'ビルドに必要な値を管理する。',
                      'Manage the values your builds need.',
                    ),
                  ),
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
              el(
                'h2',
                text: t('コードも、つくる過程も、オープンに。', 'Open code. Open development.'),
              ),
              el(
                'p',
                text: t(
                  'GenuineCIはオープンソース。あなたのアイデアを待っています。',
                  'GenuineCI is open source. Bring your ideas.',
                ),
              ),
            ],
          ),
          el(
            'a',
            attrs: {
              'href': 'https://github.com/openci-org/openci',
              'aria-label': t(
                'GitHubでGenuineCIを見る',
                'View GenuineCI on GitHub',
              ),
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
