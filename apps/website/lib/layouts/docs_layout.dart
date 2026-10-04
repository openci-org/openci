import 'dart:convert';

import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

import '../components/docs_icon.dart';
import '../components/html.dart';
import '../pages/docs_home.dart';

const docsNavigation = [
  (
    group: 'はじめに',
    items: [
      (title: 'GenuineCIへようこそ', path: '/docs/', icon: 'book'),
      (title: 'クイックスタート', path: '/docs/quickstart/', icon: 'spark'),
    ],
  ),
  (
    group: 'ワークフロー',
    items: [
      (title: 'Dartでワークフローを書く', path: '/docs/workflows/', icon: 'code'),
      (title: 'トリガー', path: '/docs/triggers/', icon: 'branch'),
      (title: 'Flutterのビルドとテスト', path: '/docs/flutter/', icon: 'box'),
      (title: 'シークレット', path: '/docs/secrets/', icon: 'lock'),
    ],
  ),
  (
    group: '環境とツール',
    items: [
      (title: 'CLIリファレンス', path: '/docs/cli/', icon: 'terminal'),
      (title: 'セルフホスト', path: '/docs/self-hosting/', icon: 'server'),
    ],
  ),
];

class GenuineDocsLayout implements PageLayout {
  const GenuineDocsLayout();
  @override
  String get name => 'genuine-docs';
  @override
  Component buildLayout(Page page, Component child) => DocsPage(page, child);
}

class DocsPage extends StatelessComponent {
  const DocsPage(this.page, this.content, {super.key});
  final Page page;
  final Component content;

  @override
  Component build(BuildContext context) {
    final data = page.data.page;
    final path = '${page.url.replaceFirst(RegExp(r'/$'), '')}/';
    final isHome = path == '/docs/';
    final title = data['title'] as String;
    final description = data['description'] as String;
    final group = data['group'] as String? ?? 'はじめに';
    final allItems = docsNavigation.expand((group) => group.items).toList();
    final current = allItems.indexWhere((item) => item.path == path);
    final searchPages = context.pages
        .where((p) => p.url.startsWith('/docs'))
        .map(
          (p) => {
            'title': p.data.page['title'],
            'description': p.data.page['description'],
            'group': p.data.page['group'] ?? 'はじめに',
            'url': '${p.url.replaceFirst(RegExp(r'/$'), '')}/',
            'body': p.content,
          },
        )
        .toList();
    final toc = isHome
        ? const [
            ('はじめの一歩', 'start'),
            ('ガイドを探す', 'guides'),
            ('いつものDartで書く', 'write-dart'),
            ('オープンにつくる', 'open-source'),
          ]
        : [
            if (page.data['toc'] case TableOfContents t)
              for (final e in t.entries) (e.text, e.id),
          ];
    Component tocLinks() => el(
      'nav',
      cls: 'd-toc-links',
      attrs: {'aria-label': 'このページの目次'},
      children: [
        for (final entry in toc) link(entry.$1, '#${entry.$2}'),
      ],
    );
    return el(
      'div',
      cls: 'docs-shell${isHome ? ' docs-overview' : ''}',
      children: [
        Document.head(
          title: '$title — GenuineCI Docs',
          meta: {'description': description},
        ),
        link('本文へスキップ', '#main', cls: 'skip-link'),
        el(
          'header',
          cls: 'd-header',
          children: [
            el(
              'div',
              cls: 'd-brand-lockup',
              children: [
                link('GenuineCI', '/', cls: 'd-wordmark'),
                el('span', cls: 'd-brand-divider', text: '/'),
                link('docs', '/docs/', cls: 'd-docs-label'),
              ],
            ),
            el(
              'button',
              cls: 'd-search-trigger',
              attrs: {
                'type': 'button',
                'data-search-open': '',
                'aria-label': 'ドキュメントを検索',
              },
              children: [
                docsIcon('search'),
                el('span', text: 'ドキュメントを検索…'),
                el('kbd', text: '⌘ K'),
              ],
            ),
            el(
              'div',
              cls: 'd-header-actions',
              children: [
                link('ブログ', '/blog/', cls: 'd-header-blog'),
                el(
                  'a',
                  cls: 'd-icon-button d-github-link',
                  attrs: {
                    'href': 'https://github.com/openci-org/openci',
                    'aria-label': 'GitHubでソースを見る',
                  },
                  children: [docsIcon('github')],
                ),
                el(
                  'a',
                  cls: 'd-dashboard',
                  attrs: {'href': 'https://dashboard.openci.org/'},
                  children: [
                    el('span', text: 'ダッシュボード'),
                    docsIcon('external'),
                  ],
                ),
              ],
            ),
          ],
        ),
        el(
          'div',
          cls: 'd-mobile-bar',
          children: [
            el(
              'button',
              cls: 'd-mobile-toggle',
              attrs: {
                'type': 'button',
                'data-menu-open': '',
                'aria-label': 'ドキュメントメニューを開く',
              },
              children: [
                docsIcon('menu'),
                el('span', text: 'メニュー'),
              ],
            ),
            el('span', text: 'GenuineCI Docs'),
          ],
        ),
        el(
          'div',
          cls: 'd-layout',
          children: [
            el('aside', cls: 'd-sidebar', children: [docsSidebar(path)]),
            el(
              'main',
              id: 'main',
              cls: 'd-main',
              attrs: {'tabindex': '-1'},
              children: [
                el(
                  'div',
                  cls: 'd-breadcrumb',
                  children: [
                    link('Docs', '/docs/'),
                    docsIcon('chevron'),
                    el('span', text: isHome ? '概要' : group),
                  ],
                ),
                if (isHome)
                  const DocsHome()
                else ...[
                  el(
                    'header',
                    cls: 'd-article-header',
                    children: [
                      el(
                        'span',
                        cls: 'd-eyebrow',
                        text: data['eyebrow'] as String? ?? 'DOCUMENTATION',
                      ),
                      el('h1', text: title),
                      el('p', cls: 'd-lead', text: description),
                      el(
                        'div',
                        cls: 'd-article-meta',
                        children: [
                          el('span', text: 'GenuineCI Docs'),
                          el('span', text: '·'),
                          el(
                            'span',
                            text: data['reading'] as String? ?? '3 min read',
                          ),
                        ],
                      ),
                    ],
                  ),
                  el(
                    'details',
                    cls: 'd-mobile-toc',
                    children: [
                      el('summary', text: 'このページの内容'),
                      tocLinks(),
                    ],
                  ),
                  el('article', cls: 'd-prose', children: [content]),
                ],
                el(
                  'nav',
                  cls: 'd-page-nav',
                  attrs: {'aria-label': '前後のドキュメント'},
                  children: [
                    if (current > 0)
                      pageLink(
                        '前のページ',
                        allItems[current - 1].title,
                        allItems[current - 1].path,
                        false,
                      )
                    else
                      el('div'),
                    if (current >= 0 && current < allItems.length - 1)
                      pageLink(
                        '次のページ',
                        allItems[current + 1].title,
                        allItems[current + 1].path,
                        true,
                      ),
                  ],
                ),
                el(
                  'footer',
                  cls: 'd-footer',
                  children: [
                    el('span', text: '© 2026 GenuineCI'),
                    el('span', text: 'BUILT IN DART. BUILT IN THE OPEN.'),
                  ],
                ),
              ],
            ),
            el(
              'aside',
              cls: 'd-toc',
              children: [
                el(
                  'div',
                  cls: 'd-toc-title',
                  children: [
                    docsIcon('list'),
                    el('span', text: 'このページの内容'),
                  ],
                ),
                tocLinks(),
                el(
                  'div',
                  cls: 'd-help',
                  children: [
                    el('span', cls: 'd-help-mark', text: 'g.'),
                    el('strong', text: '一緒につくる、Docs。'),
                    docLines('p', text: '気づいたことやアイデアを、\nGitHubで教えてください。'),
                    el(
                      'a',
                      attrs: {
                        'href': 'https://github.com/openci-org/openci/issues',
                      },
                      children: [
                        el('span', text: 'Issueを開く'),
                        docsIcon('external'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        el(
          'dialog',
          id: 'docs-menu',
          cls: 'd-menu-dialog',
          attrs: {'aria-label': 'ドキュメントメニュー'},
          children: [
            el(
              'div',
              cls: 'd-menu-heading',
              children: [
                el('strong', text: 'GenuineCI Docs'),
                el(
                  'button',
                  cls: 'd-icon-button',
                  attrs: {
                    'type': 'button',
                    'data-menu-close': '',
                    'aria-label': 'メニューを閉じる',
                  },
                  children: [docsIcon('close')],
                ),
              ],
            ),
            docsSidebar(path),
          ],
        ),
        el(
          'dialog',
          id: 'docs-search',
          cls: 'd-search-dialog',
          attrs: {'aria-labelledby': 'search-label'},
          children: [
            el(
              'div',
              cls: 'd-search-input-row',
              children: [
                docsIcon('search'),
                el(
                  'label',
                  id: 'search-label',
                  cls: 'd-sr-only',
                  attrs: {'for': 'docs-query'},
                  text: 'ドキュメントを検索',
                ),
                el(
                  'input',
                  id: 'docs-query',
                  attrs: {
                    'type': 'search',
                    'placeholder': 'キーワードで検索…',
                    'autocomplete': 'off',
                  },
                ),
                el(
                  'button',
                  cls: 'd-search-close',
                  attrs: {
                    'type': 'button',
                    'data-search-close': '',
                    'aria-label': '検索を閉じる',
                  },
                  text: 'Esc',
                ),
              ],
            ),
            el(
              'p',
              id: 'docs-search-status',
              cls: 'd-search-status',
              attrs: {'aria-live': 'polite'},
            ),
            el('div', id: 'docs-results', cls: 'd-search-results'),
            el('div', cls: 'd-search-footer', text: '↑ ↓ 選択　↵ ページを開く　esc 閉じる'),
          ],
        ),
        el(
          'script',
          id: 'docs-search-data',
          attrs: {'type': 'application/json'},
          children: [
            RawText(jsonEncode(searchPages).replaceAll('<', r'\u003c')),
          ],
        ),
      ],
    );
  }
}

Component docsSidebar(String active) => el(
  'div',
  cls: 'd-sidebar-content',
  children: [
    el(
      'a',
      cls: 'd-docs-home',
      attrs: {'href': '/docs/'},
      children: [
        el('span', cls: 'd-square-logo', text: 'g.'),
        el('span', text: 'ドキュメント'),
        el('span', cls: 'd-small-tag', text: 'DART'),
      ],
    ),
    el(
      'nav',
      attrs: {'aria-label': 'ドキュメント'},
      children: [
        for (final group in docsNavigation)
          el(
            'div',
            cls: 'd-nav-group',
            children: [
              el('h2', text: group.group),
              for (final item in group.items)
                el(
                  'a',
                  cls: 'd-nav-link${item.path == active ? ' is-active' : ''}',
                  attrs: {
                    'href': item.path,
                    if (item.path == active) 'aria-current': 'page',
                  },
                  children: [
                    docsIcon(item.icon),
                    el('span', text: item.title),
                    if (item.path == '/docs/quickstart/')
                      el('span', cls: 'd-nav-arrow', text: '↗'),
                  ],
                ),
            ],
          ),
      ],
    ),
    el(
      'div',
      cls: 'd-sidebar-bottom',
      children: [
        docLines('p', text: 'Flutter & Dartのための、\nオープンソースCI。'),
        el(
          'a',
          attrs: {'href': 'https://github.com/openci-org/openci'},
          children: [
            docsIcon('github'),
            el('span', text: 'GitHubで見る'),
            docsIcon('external'),
          ],
        ),
      ],
    ),
  ],
);

Component pageLink(String caption, String title, String path, bool next) => el(
  'a',
  cls: 'd-page-link${next ? ' is-next' : ''}',
  attrs: {'href': path},
  children: [
    el('span', text: caption),
    el(
      'strong',
      children: [
        if (!next) el('span', text: '←'),
        Component.text(title),
        if (next) docsIcon('arrow'),
      ],
    ),
  ],
);
