import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';

import '../components/dart_code.dart';
import '../components/html.dart';
import '../components/language_switcher.dart';
import '../components/pricing.dart';
import '../components/social_metadata.dart';
import '../l10n/localized_component.dart';
import '../l10n/site_locale.dart';

class LandingPage extends LocalizedComponent {
  const LandingPage(super.locale, {super.key});

  @override
  Component build(BuildContext context) => el(
    'div',
    children: [
      socialMetadata(
        title: siteTitle(locale),
        description: siteDescription(locale),
        path: localPath('/'),
        translations: {
          for (final language in SiteLocale.values)
            language: language.path('/'),
        },
      ),
      languageSwitcher(locale, {
        for (final language in SiteLocale.values) language: language.path('/'),
      }),
      link(t('本文へスキップ', 'Skip to content'), '#main', cls: 'skip-link'),
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
                attrs: {'aria-label': t('メインナビゲーション', 'Main navigation')},
                children: [
                  link(t('特長', 'Features'), '#features'),
                  link(t('ワークフロー', 'Workflows'), '#workflow'),
                  link(t('料金', 'Pricing'), '#pricing'),
                  link('Docs', localPath('/docs/')),
                  link(t('ブログ', 'Blog'), localPath('/blog/')),
                ],
              ),
              link(t('料金', 'Pricing'), '#pricing', cls: 'mobile-blog-link'),
              link(
                t('はじめる', 'Get started'),
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
              Hero(locale),
              el('div', cls: 'wrap', children: [BuildPreview(locale)]),
            ],
          ),
        ],
      ),
      el(
        'div',
        cls: 'stack-band wrap',
        children: [
          el(
            'span',
            cls: 'stack-caption',
            text: t('Flutter & Dart 専用のCI。', 'CI built for Flutter & Dart.'),
          ),
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
      Features(locale),
      Workflow(locale),
      Pricing(locale),
      GettingStarted(locale),
      Faq(locale),
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
                      Component.text(t('本物のCIを、', 'Real CI.')),
                      el('br'),
                      Component.text(t('一緒につくろう。', 'Built together.')),
                    ],
                  ),
                ],
              ),
              link(
                t('GenuineCI をはじめる', 'Get started with GenuineCI'),
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
              link('Docs', localPath('/docs/')),
              link(t('料金', 'Pricing'), '#pricing'),
              link(t('ブログ', 'Blog'), localPath('/blog/')),
              link(t('ページの先頭へ ↑', 'Back to top ↑'), '#'),
            ],
          ),
        ],
      ),
    ],
  );
}

class Hero extends LocalizedComponent {
  const Hero(super.locale, {super.key});
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
              Component.text(t('Flutter & Dartに、', 'For Flutter & Dart.')),
              el('br'),
              Component.text(t('本物のCIを。', 'Real CI.')),
            ],
          ),
          el(
            'div',
            cls: 'hero-description',
            children: [
              el(
                'p',
                children: [
                  Component.text(
                    t(
                      'Dartで書かれた、Flutter & Dart専用のCI。',
                      'CI for Flutter & Dart, built in Dart.',
                    ),
                  ),
                  el('br'),
                  Component.text(
                    t(
                      'ワークフローもDartで定義。Apple Siliconで動く、セルフホストも可能なオープンソースCIです。',
                      'Write your workflows in Dart. Run on Apple Silicon. Open source, with the freedom to self-host.',
                    ),
                  ),
                ],
              ),
              el(
                'div',
                cls: 'hero-actions',
                children: [
                  link(
                    t('GenuineCI をはじめる', 'Get started with GenuineCI'),
                    '#get-started',
                    cls: 'button button-dark',
                    arrow: 'arrow',
                  ),
                  link(
                    t('仕組みを見る', 'See how it works'),
                    '#workflow',
                    cls: 'text-link',
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

class BuildPreview extends LocalizedComponent {
  const BuildPreview(super.locale, {super.key});
  @override
  Component build(BuildContext context) => el(
    'section',
    cls: 'build-preview',
    attrs: {
      'aria-label': t('ビルド画面のデザインプレビュー', 'Build dashboard design preview'),
    },
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
                      el('span', cls: 'sample-note', text: t('サンプル', 'Sample')),
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

class Features extends LocalizedComponent {
  const Features(super.locale, {super.key});
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
              Component.text(t('本物のCIを、', 'Real CI.')),
              el('br'),
              Component.text(t('オープンにつくる。', 'Built in the open.')),
            ],
          ),
          el(
            'p',
            text: t(
              'Genuineは「本物」。Flutter & Dartの開発者にとって、本当に使いたいCIをつくる。そのための、オープンソースプロジェクトです。',
              'Genuine means real. We are building the CI that Flutter & Dart developers want to use, as an open-source project.',
            ),
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
            t('Flutter & Dartのために。', 'Made for Flutter & Dart.'),
            t(
              'GenuineCI自体もDartで書かれています。FlutterアプリもDartパッケージも、いつもの言語でワークフローから支えます。',
              'GenuineCI itself is written in Dart. Use a familiar language to write workflows for your Flutter apps and Dart packages.',
            ),
            ['Built with Dart', 'Dart workflows'],
          ),
          feature(
            'branch',
            '02',
            t('Apple Siliconで動かす。', 'Run on Apple Silicon.'),
            t(
              '現在の実行マシンはApple Siliconのみ。M1・M2・M3・M4をサポートし、Mac上でビルドとテストを実行します。',
              'Builds and tests currently run on Apple Silicon Macs, with support for M1, M2, M3, and M4.',
            ),
            ['M1 / M2 / M3 / M4', 'macOS'],
          ),
          feature(
            'terminal',
            '03',
            t('コードも、運用も、自分の手で。', 'Your code. Your machines.'),
            t(
              'GenuineCIはOSS。ソースコードを読んで、改善に参加することも、自分のApple Siliconマシンでセルフホストすることもできます。',
              'Read the source, contribute improvements, or self-host on your own Apple Silicon machines. GenuineCI is open source.',
            ),
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
          t('GitHubでソースを見る', 'View source on GitHub'),
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

class Workflow extends LocalizedComponent {
  const Workflow(super.locale, {super.key});
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
                  Component.text(t('ワークフローも、', 'Your workflows.')),
                  el('br'),
                  Component.text(t('いつものDartで。', 'The Dart you know.')),
                ],
              ),
              el(
                'p',
                text: t(
                  'ビルドやテストの手順を、Dartのコードで定義。関数、条件分岐、ループ。アプリ開発で使い慣れた書き方を、そのままCIにも。',
                  'Define build and test steps in Dart. Functions, conditionals, and loops: bring the code you already know to your CI.',
                ),
              ),
              el(
                'ul',
                cls: 'check-list',
                children: [
                  for (final item in [
                    t('Dartでワークフローを定義する', 'Define workflows in Dart'),
                    t('関数にまとめて、手順を再利用する', 'Reuse steps with functions'),
                    t(
                      'Flutter & Dartの解析・テストを実行する',
                      'Analyze and test Flutter & Dart projects',
                    ),
                  ])
                    el('li', children: [icon('check'), Component.text(item)]),
                ],
              ),
              link(
                t('はじめ方を見る', 'See how to get started'),
                '#get-started',
                cls: 'text-link',
                arrow: 'arrow',
              ),
            ],
          ),
          DartWorkflowPreview(locale),
        ],
      ),
    ],
  );
}

Map<String, List<String>> workflowExamples(SiteLocale locale) => {
  'Flutter': [
    locale.text(
      '// flutter_ci.dart — 処理部分',
      '// flutter_ci.dart — workflow steps',
    ),
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
    locale.text('// dart_ci.dart — 処理部分', '// dart_ci.dart — workflow steps'),
    'for (final command in [',
    "  'dart pub get',",
    "  'dart analyze',",
    "  'dart test',",
    ']) {',
    '  await ci.run(command);',
    '}',
  ],
};

class DartWorkflowPreview extends LocalizedComponent {
  const DartWorkflowPreview(super.locale, {super.key});

  @override
  Component build(BuildContext context) => el(
    'div',
    cls: 'code-panel',
    children: [
      el(
        'div',
        cls: 'code-tabs',
        attrs: {
          'role': 'tablist',
          'aria-label': t(
            'Dartで定義するワークフローの例',
            'Example workflows written in Dart',
          ),
        },
        children: [
          for (final name in workflowExamples(locale).keys)
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
      for (final entry in workflowExamples(locale).entries)
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
              Component.text(
                t(
                  'Dartワークフロー · 初期化部分は省略',
                  'Dart workflow · initialization omitted',
                ),
              ),
            ],
          ),
          el('span', text: 'Apple Silicon'),
        ],
      ),
    ],
  );
}

class GettingStarted extends LocalizedComponent {
  const GettingStarted(super.locale, {super.key});
  @override
  Component build(BuildContext context) => el(
    'section',
    id: 'get-started',
    cls: 'section wrap getting-started',
    children: [
      label('04', 'YOUR FIRST BUILD STARTS HERE'),
      el(
        'div',
        cls: 'section-heading',
        children: [
          el('h2', text: t('まずは、ひとつのビルドから。', 'Start with one build.')),
          link(
            t('ダッシュボードを開く', 'Open dashboard'),
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
              t('プロジェクトを選ぶ', 'Choose a project'),
              t(
                'FlutterアプリやDartパッケージ。まずはCIで確かめたいプロジェクトを用意します。',
                'Pick the Flutter app or Dart package you want to check with CI.',
              ),
            ),
            (
              '02',
              t('Dartで手順を書く', 'Write your steps in Dart'),
              t(
                '静的解析、テスト、ビルド。必要な処理をDartのワークフローとして定義します。',
                'Analysis, tests, and builds. Define the steps you need as a Dart workflow.',
              ),
            ),
            (
              '03',
              t('Apple Siliconで実行', 'Run on Apple Silicon'),
              t(
                'M1〜M4のMacでワークフローを実行。自分のマシンでセルフホストすることもできます。',
                'Run your workflow on an M1–M4 Mac. You can also self-host on your own machines.',
              ),
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

class Faq extends LocalizedComponent {
  const Faq(super.locale, {super.key});
  @override
  Component build(BuildContext context) => el(
    'section',
    cls: 'faq-section wrap',
    children: [
      el(
        'div',
        children: [
          label('05', 'GOOD TO KNOW'),
          el('h2', text: t('よくある質問', 'Frequently asked questions')),
        ],
      ),
      el(
        'div',
        cls: 'faq-list',
        children: [
          for (final item in [
            (
              t('GenuineCIという名前には、どんな意味がありますか？', 'What does GenuineCI mean?'),
              t(
                'Genuineは「本物」という意味です。Flutter & Dartの開発者にとって、本当に使いたい、本物のCIをつくることを目指しています。',
                'Genuine means real. Our goal is to build real CI that Flutter & Dart developers want to use.',
              ),
            ),
            (
              t('どんなプロジェクトに対応していますか？', 'What projects does it support?'),
              t(
                'Flutter & Dart専用です。FlutterアプリやDartパッケージの静的解析、テスト、ビルドなどを、Dartで定義したワークフローで実行します。',
                'GenuineCI is built for Flutter & Dart. Run analysis, tests, builds, and more for Flutter apps and Dart packages using workflows written in Dart.',
              ),
            ),
            (
              t('どのマシンで動きますか？', 'What machines does it run on?'),
              t(
                '現在はApple Silicon搭載のMacのみが対象です。M1・M2・M3・M4に対応しています。',
                'Currently, Apple Silicon Macs are supported: M1, M2, M3, and M4.',
              ),
            ),
            (
              t('セルフホストできますか？', 'Can I self-host?'),
              t(
                'はい。GenuineCIはオープンソースです。自分のApple Siliconマシンを使ってセルフホストすることもできます。',
                'Yes. GenuineCI is open source, and you can self-host on your own Apple Silicon machines.',
              ),
            ),
            (
              t('GenuineCI自体は何で書かれていますか？', 'What is GenuineCI built with?'),
              t(
                'GenuineCIはDartで書かれています。サービス自体の実装も、利用するワークフローの定義もDartです。',
                'GenuineCI is written in Dart. Both the service and your workflow definitions use Dart.',
              ),
            ),
            (
              t('ワークフローは何で書きますか？', 'How do I write a workflow?'),
              t(
                'Dartで定義します。関数や条件分岐、ループなど、Dartの言語機能を使ってビルドやテストの手順を組み立てられます。',
                'Write it in Dart. Use functions, conditionals, loops, and other Dart language features to put together your build and test steps.',
              ),
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
