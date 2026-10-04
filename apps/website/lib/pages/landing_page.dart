import 'package:jaspr/server.dart';
import 'package:jaspr/dom.dart' show RawText;

import '../components/dart_code.dart';
import '../components/html.dart';
import '../components/social_metadata.dart';

class LandingPage extends StatelessComponent {
  const LandingPage({super.key});

  @override
  Component build(BuildContext context) => el(
    'div',
    children: [
      socialMetadata(title: siteTitle, description: siteDescription, path: '/'),
      link('本文へスキップ', '#main', cls: 'skip-link'),
      el(
        'div',
        cls: 'hero-shell',
        children: [
          el(
            'header',
            cls: 'site-header wrap',
            children: [
              link('GenuineCI', '#', cls: 'brand'),
              el(
                'nav',
                cls: 'desktop-nav',
                attrs: {'aria-label': 'メインナビゲーション'},
                children: [
                  link('特長', '#features'),
                  link('ワークフロー', '#workflow'),
                  link('はじめ方', '#get-started'),
                  link('Docs', '/docs/'),
                  link('ブログ', '/blog/'),
                ],
              ),
              link('Docs', '/docs/', cls: 'mobile-blog-link'),
              link(
                'はじめる',
                '#get-started',
                cls: 'button button-small button-dark',
                arrow: 'arrow',
              ),
            ],
          ),
          el(
            'main',
            id: 'main',
            children: [
              const Hero(),
              el('div', cls: 'wrap', children: [const BuildPreview()]),
            ],
          ),
        ],
      ),
      el(
        'div',
        cls: 'stack-band wrap',
        children: [
          el('span', cls: 'stack-caption', text: 'Flutter & Dart 専用のCI。'),
          el(
            'div',
            cls: 'stack-names',
            children: [
              el('span', text: 'Flutter'),
              el('span', text: 'Dart'),
              el('span', text: 'Apple Silicon'),
              el('span', text: 'Open source'),
            ],
          ),
        ],
      ),
      const Features(),
      const Workflow(),
      const GettingStarted(),
      const Faq(),
      el(
        'section',
        cls: 'closing',
        children: [
          el(
            'div',
            cls: 'wrap closing-content',
            children: [
              el(
                'div',
                children: [
                  el('p', cls: 'eyebrow', text: 'GENUINE MEANS REAL.'),
                  el(
                    'h2',
                    children: [
                      Component.text('本物のCIを、'),
                      el('br'),
                      Component.text('一緒につくろう。'),
                    ],
                  ),
                ],
              ),
              link(
                'GenuineCI をはじめる',
                '#get-started',
                cls: 'button button-dark',
                arrow: 'arrow',
              ),
            ],
          ),
          el(
            'div',
            cls: 'wrap footer-wordmark',
            text: 'GenuineCI',
            attrs: {'aria-hidden': 'true'},
          ),
        ],
      ),
      el(
        'footer',
        cls: 'site-footer',
        children: [
          el(
            'div',
            cls: 'wrap footer-inner',
            children: [
              el('span', text: '© 2026 GenuineCI'),
              el(
                'span',
                cls: 'footer-tagline',
                text: 'Open source. Built for Flutter & Dart.',
              ),
              link('Docs', '/docs/'),
              link('ブログ', '/blog/'),
              link('ページの先頭へ ↑', '#'),
            ],
          ),
        ],
      ),
    ],
  );
}

class Hero extends StatelessComponent {
  const Hero({super.key});
  @override
  Component build(BuildContext context) => el(
    'section',
    cls: 'hero wrap',
    children: [
      el(
        'div',
        cls: 'hero-kicker',
        children: [
          el('span', text: 'BUILT IN DART. MADE FOR FLUTTER & DART.'),
          el('span', text: 'OPEN SOURCE. YOUR MACHINES, TOO.'),
        ],
      ),
      el(
        'div',
        cls: 'hero-wordmark',
        text: 'GenuineCI',
        attrs: {'aria-label': 'GenuineCI'},
      ),
      el(
        'div',
        cls: 'hero-story',
        children: [
          el(
            'h1',
            children: [
              Component.text('Flutter & Dartに、'),
              el('br'),
              Component.text('本物のCIを。'),
            ],
          ),
          el(
            'div',
            cls: 'hero-description',
            children: [
              el(
                'p',
                children: [
                  Component.text('Dartで書かれた、Flutter & Dart専用のCI。'),
                  el('br'),
                  Component.text(
                    'ワークフローもDartで定義。Apple Siliconで動く、セルフホストも可能なオープンソースCIです。',
                  ),
                ],
              ),
              el(
                'div',
                cls: 'hero-actions',
                children: [
                  link(
                    'GenuineCI をはじめる',
                    '#get-started',
                    cls: 'button button-dark',
                    arrow: 'arrow',
                  ),
                  link('仕組みを見る', '#workflow', cls: 'text-link'),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class BuildPreview extends StatelessComponent {
  const BuildPreview({super.key});
  @override
  Component build(BuildContext context) => el(
    'section',
    cls: 'build-preview',
    attrs: {'aria-label': 'ビルド画面のデザインプレビュー'},
    children: [
      el(
        'div',
        cls: 'window-top',
        children: [
          el(
            'div',
            cls: 'window-dots',
            attrs: {'aria-hidden': 'true'},
            children: [el('i'), el('i'), el('i')],
          ),
          el('span', text: 'GenuineCI / workspace / your-flutter-app'),
          el('span', cls: 'preview-label', text: 'UI PREVIEW'),
        ],
      ),
      el(
        'div',
        cls: 'dashboard-body',
        children: [
          el(
            'aside',
            cls: 'dashboard-sidebar',
            children: [
              el(
                'div',
                cls: 'workspace-name',
                children: [
                  el('span', cls: 'workspace-icon', text: 'g'),
                  el('span', text: 'Your workspace'),
                ],
              ),
              el(
                'div',
                cls: 'sidebar-item',
                children: [
                  icon('grid'),
                  el('span', text: 'Overview'),
                ],
              ),
              el(
                'div',
                cls: 'sidebar-item selected',
                children: [
                  icon('play'),
                  el('span', text: 'Builds'),
                  el('span', cls: 'count', text: '24'),
                ],
              ),
              el(
                'div',
                cls: 'sidebar-item',
                children: [
                  icon('branch'),
                  el('span', text: 'Workflows'),
                ],
              ),
              el(
                'div',
                cls: 'sidebar-item',
                children: [
                  icon('box'),
                  el('span', text: 'Artifacts'),
                ],
              ),
              el(
                'div',
                cls: 'sidebar-bottom',
                children: [
                  el('span', cls: 'avatar', text: 'Y'),
                  el('span', text: 'Your team'),
                ],
              ),
            ],
          ),
          el(
            'div',
            cls: 'dashboard-main',
            children: [
              el(
                'div',
                cls: 'build-heading',
                children: [
                  el(
                    'div',
                    children: [
                      el(
                        'p',
                        cls: 'build-breadcrumb',
                        text: 'your-flutter-app / flutter_ci.dart / #128',
                      ),
                      el('h2', text: 'Flutter CI — all checks passed.'),
                    ],
                  ),
                  el(
                    'span',
                    cls: 'status-badge',
                    children: [
                      icon('check'),
                      el('span', text: 'Passed'),
                    ],
                  ),
                ],
              ),
              el(
                'div',
                cls: 'build-meta',
                children: [
                  el(
                    'span',
                    children: [icon('branch'), Component.text('main')],
                  ),
                  el('span', cls: 'commit', text: 'a1b2c3d'),
                  el(
                    'span',
                    children: [icon('cpu'), Component.text('macOS · Apple M4')],
                  ),
                  el(
                    'span',
                    children: [icon('clock'), Component.text('2m 48s')],
                  ),
                ],
              ),
              el(
                'div',
                cls: 'pipeline',
                children: [
                  for (final step in [
                    ('Checkout', '4s'),
                    ('Analyze', '18s'),
                    ('Test', '42s'),
                    ('Build', '1m 44s'),
                  ])
                    el(
                      'div',
                      cls: 'pipeline-step',
                      children: [
                        el(
                          'div',
                          cls: 'step-top',
                          children: [
                            el(
                              'span',
                              cls: 'check-circle',
                              children: [icon('check')],
                            ),
                            el('strong', text: step.$1),
                          ],
                        ),
                        el('span', cls: 'step-time', text: step.$2),
                      ],
                    ),
                ],
              ),
              el(
                'div',
                cls: 'terminal-preview',
                children: [
                  el(
                    'div',
                    cls: 'terminal-title',
                    children: [
                      icon('terminal'),
                      el('span', text: 'Build output'),
                      el('span', cls: 'sample-note', text: 'サンプル'),
                    ],
                  ),
                  el(
                    'div',
                    cls: 'terminal-line',
                    children: [
                      el('span', text: '01'),
                      el('code', text: r'$ dart run flutter_ci.dart'),
                    ],
                  ),
                  el(
                    'div',
                    cls: 'terminal-line muted-line',
                    children: [
                      el('span', text: '02'),
                      el(
                        'code',
                        text: 'Running Flutter analysis, tests and build…',
                      ),
                    ],
                  ),
                  el(
                    'div',
                    cls: 'terminal-line success-line',
                    children: [
                      el('span', text: '03'),
                      el(
                        'code',
                        text: '✓ Workflow completed on Apple Silicon.',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class Features extends StatelessComponent {
  const Features({super.key});
  @override
  Component build(BuildContext context) => el(
    'section',
    id: 'features',
    cls: 'section wrap features',
    children: [
      label('01', 'WHAT MAKES IT GENUINE'),
      el(
        'div',
        cls: 'section-heading',
        children: [
          el(
            'h2',
            children: [
              Component.text('本物のCIを、'),
              el('br'),
              Component.text('オープンにつくる。'),
            ],
          ),
          el(
            'p',
            text: 'Genuineは「本物」。Flutter & Dartの開発者にとって、本当に使いたいCIをつくる。そのための、オープンソースプロジェクトです。',
          ),
        ],
      ),
      el(
        'div',
        cls: 'feature-grid',
        children: [
          feature(
            'cpu',
            '01',
            'Flutter & Dartのために。',
            'GenuineCI自体もDartで書かれています。FlutterアプリもDartパッケージも、いつもの言語でワークフローから支えます。',
            ['Built with Dart', 'Dart workflows'],
          ),
          feature(
            'branch',
            '02',
            'Apple Siliconで動かす。',
            '現在の実行マシンはApple Siliconのみ。M1・M2・M3・M4をサポートし、Mac上でビルドとテストを実行します。',
            ['M1 / M2 / M3 / M4', 'macOS'],
          ),
          feature(
            'terminal',
            '03',
            'コードも、運用も、自分の手で。',
            'GenuineCIはOSS。ソースコードを読んで、改善に参加することも、自分のApple Siliconマシンでセルフホストすることもできます。',
            ['Open source', 'Self-hosted'],
          ),
        ],
      ),
    ],
  );
  Component feature(
    String symbol,
    String number,
    String title,
    String body,
    List<String> tags,
  ) => el(
    'article',
    cls: 'feature',
    children: [
      el(
        'div',
        cls: 'feature-top',
        children: [
          el('span', cls: 'feature-icon', children: [icon(symbol)]),
          el('span', text: '/ $number'),
        ],
      ),
      el('h3', text: title),
      el('p', text: body),
      if (number == '03')
        link(
          'GitHubでソースを見る',
          'https://github.com/openci-org/openci',
          cls: 'text-link feature-source',
          arrow: 'external',
        ),
      el(
        'div',
        cls: 'feature-tags',
        children: [for (final tag in tags) el('span', text: tag)],
      ),
    ],
  );
}

class Workflow extends StatelessComponent {
  const Workflow({super.key});
  @override
  Component build(BuildContext context) => el(
    'section',
    id: 'workflow',
    cls: 'workflow-section',
    children: [
      el(
        'div',
        cls: 'wrap workflow-grid',
        children: [
          el(
            'div',
            cls: 'workflow-copy',
            children: [
              label('02', 'YOUR WORKFLOW IS DART'),
              el(
                'h2',
                children: [
                  Component.text('ワークフローも、'),
                  el('br'),
                  Component.text('いつものDartで。'),
                ],
              ),
              el(
                'p',
                text: 'ビルドやテストの手順を、Dartのコードで定義。関数、条件分岐、ループ。アプリ開発で使い慣れた書き方を、そのままCIにも。',
              ),
              el(
                'ul',
                cls: 'check-list',
                children: [
                  for (final item in [
                    'Dartでワークフローを定義する',
                    '関数にまとめて、手順を再利用する',
                    'Flutter & Dartの解析・テストを実行する',
                  ])
                    el('li', children: [icon('check'), Component.text(item)]),
                ],
              ),
              link('はじめ方を見る', '#get-started', cls: 'text-link', arrow: 'arrow'),
            ],
          ),
          const DartWorkflowPreview(),
        ],
      ),
    ],
  );
}

const workflowExamples = {
  'Flutter': [
    '// flutter_ci.dart — 処理部分',
    "await ci.run('flutter pub get');",
    '',
    'await ci.flutter.staticAnalysis();',
    'await ci.flutter.unitTests();',
    '',
    'await ci.run(',
    "  'flutter build ios --no-codesign',",
    ');',
  ],
  'Dart': [
    '// dart_ci.dart — 処理部分',
    'for (final command in [',
    "  'dart pub get',",
    "  'dart analyze',",
    "  'dart test',",
    ']) {',
    '  await ci.run(command);',
    '}',
  ],
};

class DartWorkflowPreview extends StatelessComponent {
  const DartWorkflowPreview({super.key});

  @override
  Component build(BuildContext context) => el(
    'div',
    cls: 'code-panel',
    children: [
      el(
        'div',
        cls: 'code-tabs',
        attrs: {'role': 'tablist', 'aria-label': 'Dartで定義するワークフローの例'},
        children: [
          for (final name in workflowExamples.keys)
            el(
              'button',
              id: 'tab-${name.toLowerCase()}',
              cls: name == 'Flutter' ? 'code-tab active' : 'code-tab',
              text: name,
              attrs: {
                'type': 'button',
                'role': 'tab',
                'aria-selected': name == 'Flutter' ? 'true' : 'false',
                'aria-controls': 'workflow-${name.toLowerCase()}',
                'tabindex': name == 'Flutter' ? '0' : '-1',
                'data-workflow': name.toLowerCase(),
              },
            ),
          el('span', cls: 'code-filetype', text: 'DART'),
        ],
      ),
      for (final entry in workflowExamples.entries)
        el(
          'div',
          id: 'workflow-${entry.key.toLowerCase()}',
          cls: 'code-content dart-content',
          attrs: {
            'role': 'tabpanel',
            'aria-labelledby': 'tab-${entry.key.toLowerCase()}',
            'tabindex': '0',
            if (entry.key != 'Flutter') 'hidden': '',
          },
          children: [
            for (final (index, line) in entry.value.indexed)
              el(
                'div',
                cls: 'dart-line',
                children: [
                  el(
                    'span',
                    cls: 'line-number',
                    text: '${index + 1}',
                    attrs: {'aria-hidden': 'true'},
                  ),
                  RawText('<code>${highlightedDart(line)}</code>'),
                ],
              ),
          ],
        ),
      el(
        'div',
        cls: 'code-footer',
        children: [
          el(
            'span',
            children: [
              icon('terminal'),
              Component.text('Dartワークフロー · 初期化部分は省略'),
            ],
          ),
          el('span', text: 'Apple Silicon'),
        ],
      ),
    ],
  );
}

class GettingStarted extends StatelessComponent {
  const GettingStarted({super.key});
  @override
  Component build(BuildContext context) => el(
    'section',
    id: 'get-started',
    cls: 'section wrap getting-started',
    children: [
      label('03', 'YOUR FIRST BUILD STARTS HERE'),
      el(
        'div',
        cls: 'section-heading',
        children: [
          el('h2', text: 'まずは、ひとつのビルドから。'),
          link(
            'ダッシュボードを開く',
            'https://dashboard.openci.org/',
            cls: 'button button-outline',
            arrow: 'external',
          ),
        ],
      ),
      el(
        'ol',
        cls: 'setup-steps',
        children: [
          for (final step in [
            (
              '01',
              'プロジェクトを選ぶ',
              'FlutterアプリやDartパッケージ。まずはCIで確かめたいプロジェクトを用意します。',
            ),
            ('02', 'Dartで手順を書く', '静的解析、テスト、ビルド。必要な処理をDartのワークフローとして定義します。'),
            (
              '03',
              'Apple Siliconで実行',
              'M1〜M4のMacでワークフローを実行。自分のマシンでセルフホストすることもできます。',
            ),
          ])
            el(
              'li',
              children: [
                el('span', cls: 'setup-number', text: step.$1),
                el('h3', text: step.$2),
                el('p', text: step.$3),
              ],
            ),
        ],
      ),
    ],
  );
}

class Faq extends StatelessComponent {
  const Faq({super.key});
  @override
  Component build(BuildContext context) => el(
    'section',
    cls: 'faq-section wrap',
    children: [
      el(
        'div',
        children: [
          label('04', 'GOOD TO KNOW'),
          el('h2', text: 'よくある質問'),
        ],
      ),
      el(
        'div',
        cls: 'faq-list',
        children: [
          for (final item in [
            (
              'GenuineCIという名前には、どんな意味がありますか？',
              'Genuineは「本物」という意味です。Flutter & Dartの開発者にとって、本当に使いたい、本物のCIをつくることを目指しています。',
            ),
            (
              'どんなプロジェクトに対応していますか？',
              'Flutter & Dart専用です。FlutterアプリやDartパッケージの静的解析、テスト、ビルドなどを、Dartで定義したワークフローで実行します。',
            ),
            (
              'どのマシンで動きますか？',
              '現在はApple Silicon搭載のMacのみが対象です。M1・M2・M3・M4に対応しています。',
            ),
            (
              'セルフホストできますか？',
              'はい。GenuineCIはオープンソースです。自分のApple Siliconマシンを使ってセルフホストすることもできます。',
            ),
            (
              'GenuineCI自体は何で書かれていますか？',
              'GenuineCIはDartで書かれています。サービス自体の実装も、利用するワークフローの定義もDartです。',
            ),
            (
              'ワークフローは何で書きますか？',
              'Dartで定義します。関数や条件分岐、ループなど、Dartの言語機能を使ってビルドやテストの手順を組み立てられます。',
            ),
          ])
            el(
              'details',
              children: [
                el(
                  'summary',
                  children: [
                    Component.text(item.$1),
                    el(
                      'span',
                      cls: 'faq-plus',
                      text: '+',
                      attrs: {'aria-hidden': 'true'},
                    ),
                  ],
                ),
                el('p', text: item.$2),
              ],
            ),
        ],
      ),
    ],
  );
}
