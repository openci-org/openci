import 'dart:convert';

import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

import '../components/docs_icon.dart';
import '../components/html.dart';
import '../components/language_switcher.dart';
import '../components/social_metadata.dart';
import '../l10n/localized_component.dart';
import '../l10n/site_locale.dart';
import '../pages/docs_home.dart';

List<({String group, List<({String title, String path, String icon})> items})>
docsNavigation(SiteLocale locale) => [
  (
    group: locale.text('はじめに', 'Getting started'),
    items: [
      (
        title: locale.text('GenuineCIへようこそ', 'Welcome to GenuineCI'),
        path: locale.path('/docs/'),
        icon: 'book',
      ),
      (
        title: locale.text('クイックスタート', 'Quickstart'),
        path: locale.path('/docs/quickstart/'),
        icon: 'spark',
      ),
    ],
  ),
  (
    group: locale.text('ワークフロー', 'Workflows'),
    items: [
      (
        title: locale.text('Dartでワークフローを書く', 'Write workflows in Dart'),
        path: locale.path('/docs/workflows/'),
        icon: 'code',
      ),
      (
        title: locale.text('トリガー', 'Triggers'),
        path: locale.path('/docs/triggers/'),
        icon: 'branch',
      ),
      (
        title: locale.text('Flutterのビルドとテスト', 'Build and test Flutter'),
        path: locale.path('/docs/flutter/'),
        icon: 'box',
      ),
      (
        title: locale.text('シークレット', 'Secrets'),
        path: locale.path('/docs/secrets/'),
        icon: 'lock',
      ),
    ],
  ),
  (
    group: locale.text('環境とツール', 'Environment and tools'),
    items: [
      (
        title: locale.text('CLIリファレンス', 'CLI reference'),
        path: locale.path('/docs/cli/'),
        icon: 'terminal',
      ),
      (
        title: locale.text('セルフホスト', 'Self-hosting'),
        path: locale.path('/docs/self-hosting/'),
        icon: 'server',
      ),
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

class DocsPage extends LocalizedComponent {
  DocsPage(this.page, this.content, {super.key})
    : super(SiteLocale.fromPath(page.url));
  final Page page;
  final Component content;

  @override
  Component build(BuildContext context) {
    final translations = availableTranslations(
      page.url,
      context.pages.map((p) => p.url),
    );
    final data = page.data.page;
    final path = '${page.url.replaceFirst(RegExp(r'/$'), '')}/';
    final isHome = path == localPath('/docs/');
    final title = data['title'] as String;
    final description = data['description'] as String;
    final group = data['group'] as String? ?? t('はじめに', 'Getting started');
    final allItems = docsNavigation(
      locale,
    ).expand((group) => group.items).toList();
    final current = allItems.indexWhere((item) => item.path == path);
    final searchPages = context.pages
        .where(
          (p) =>
              p.url == localPath('/docs/').replaceFirst(RegExp(r'/$'), '') ||
              p.url.startsWith(localPath('/docs/')),
        )
        .map(
          (p) => {
            'title': p.data.page['title'],
            'description': p.data.page['description'],
            'group': p.data.page['group'] ?? t('はじめに', 'Getting started'),
            'url': '${p.url.replaceFirst(RegExp(r'/$'), '')}/',
            'body': p.content,
          },
        )
        .toList();
    final toc = isHome
        ? [
            (t('はじめの一歩', 'First steps'), 'start'),
            (t('ガイドを探す', 'Explore guides'), 'guides'),
            (t('いつものDartで書く', 'Write in Dart'), 'write-dart'),
            (t('オープンにつくる', 'Build in the open'), 'open-source'),
          ]
        : [
            if (page.data['toc'] case TableOfContents t)
              for (final e in t.entries) (e.text, e.id),
          ];
    Component tocLinks() => el(
      'nav',
      cls: 'd-toc-links',
      attrs: {'aria-label': t('このページの目次', 'On this page')},
      children: [
        for (final entry in toc) link(entry.$1, '#${entry.$2}'),
      ],
    );
    return el(
      'div',
      cls: 'docs-shell${isHome ? ' docs-overview' : ''}',
      children: [
        socialMetadata(
          title: '$title — GenuineCI Docs',
          description: description,
          path: path,
          translations: translations,
        ),
        languageSwitcher(locale, translations),
        link(t('本文へスキップ', 'Skip to content'), '#main', cls: 'skip-link'),
        el(
          'header',
          cls: 'd-header',
          children: [
            el(
              'div',
              cls: 'd-brand-lockup',
              children: [
                link('GenuineCI', localPath('/'), cls: 'd-wordmark'),
                el('span', cls: 'd-brand-divider', text: '/'),
                link('docs', localPath('/docs/'), cls: 'd-docs-label'),
              ],
            ),
            el(
              'button',
              cls: 'd-search-trigger',
              attrs: {
                'type': 'button',
                'data-search-open': '',
                'aria-label': t('ドキュメントを検索', 'Search documentation'),
              },
              children: [
                docsIcon('search'),
                el('span', text: t('ドキュメントを検索…', 'Search docs…')),
                el('kbd', text: '⌘ K'),
              ],
            ),
            el(
              'div',
              cls: 'd-header-actions',
              children: [
                link(
                  t('ブログ', 'Blog'),
                  localPath('/blog/'),
                  cls: 'd-header-blog',
                ),
                el(
                  'a',
                  cls: 'd-icon-button d-github-link',
                  attrs: {
                    'href': 'https://github.com/openci-org/openci',
                    'aria-label': t('GitHubでソースを見る', 'View source on GitHub'),
                  },
                  children: [docsIcon('github')],
                ),
                el(
                  'a',
                  cls: 'd-dashboard',
                  attrs: {'href': 'https://dashboard.openci.org/'},
                  children: [
                    el('span', text: t('ダッシュボード', 'Dashboard')),
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
                'aria-label': t('ドキュメントメニューを開く', 'Open documentation menu'),
              },
              children: [
                docsIcon('menu'),
                el('span', text: t('メニュー', 'Menu')),
              ],
            ),
            el('span', text: 'GenuineCI Docs'),
          ],
        ),
        el(
          'div',
          cls: 'd-layout',
          children: [
            el(
              'aside',
              cls: 'd-sidebar',
              children: [docsSidebar(locale, path)],
            ),
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
                    link('Docs', localPath('/docs/')),
                    docsIcon('chevron'),
                    el('span', text: isHome ? t('概要', 'Overview') : group),
                  ],
                ),
                if (isHome)
                  DocsHome(locale)
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
                      el('summary', text: t('このページの内容', 'On this page')),
                      tocLinks(),
                    ],
                  ),
                  el('article', cls: 'd-prose', children: [content]),
                ],
                el(
                  'nav',
                  cls: 'd-page-nav',
                  attrs: {
                    'aria-label': t('前後のドキュメント', 'Previous and next guides'),
                  },
                  children: [
                    if (current > 0)
                      pageLink(
                        t('前のページ', 'Previous'),
                        allItems[current - 1].title,
                        allItems[current - 1].path,
                        false,
                      )
                    else
                      el('div'),
                    if (current >= 0 && current < allItems.length - 1)
                      pageLink(
                        t('次のページ', 'Next'),
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
                    el('span', text: t('このページの内容', 'On this page')),
                  ],
                ),
                tocLinks(),
                el(
                  'div',
                  cls: 'd-help',
                  children: [
                    el('span', cls: 'd-help-mark', text: 'g.'),
                    el(
                      'strong',
                      text: t('一緒につくる、Docs。', 'Build better docs together.'),
                    ),
                    docLines(
                      'p',
                      text: t(
                        '気づいたことやアイデアを、\nGitHubで教えてください。',
                        'Share feedback and ideas\non GitHub.',
                      ),
                    ),
                    el(
                      'a',
                      attrs: {
                        'href': 'https://github.com/openci-org/openci/issues',
                      },
                      children: [
                        el('span', text: t('Issueを開く', 'Open an issue')),
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
          attrs: {'aria-label': t('ドキュメントメニュー', 'Documentation menu')},
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
                    'aria-label': t('メニューを閉じる', 'Close menu'),
                  },
                  children: [docsIcon('close')],
                ),
              ],
            ),
            docsSidebar(locale, path),
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
                  text: t('ドキュメントを検索', 'Search documentation'),
                ),
                el(
                  'input',
                  id: 'docs-query',
                  attrs: {
                    'type': 'search',
                    'placeholder': t('キーワードで検索…', 'Search by keyword…'),
                    'autocomplete': 'off',
                  },
                ),
                el(
                  'button',
                  cls: 'd-search-close',
                  attrs: {
                    'type': 'button',
                    'data-search-close': '',
                    'aria-label': t('検索を閉じる', 'Close search'),
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
            el(
              'div',
              cls: 'd-search-footer',
              text: t(
                '↑ ↓ 選択　↵ ページを開く　esc 閉じる',
                '↑ ↓ Select　↵ Open page　esc Close',
              ),
            ),
          ],
        ),
        el(
          'script',
          id: 'docs-ui-text',
          attrs: {'type': 'application/json'},
          children: [
            RawText(
              jsonEncode({
                'results': t('{count}件のドキュメント', '{count} documents'),
                'search': t('ドキュメントから探す', 'Search documentation'),
                'empty': t(
                  '見つかりませんでした。別のキーワードで試してください。',
                  'No results. Try another keyword.',
                ),
                'copied': t('コピー済み', 'Copied'),
                'copiedLabel': t('コピーしました', 'Code copied'),
                'copy': t('コピー', 'Copy'),
                'copyLabel': t('コードをコピー', 'Copy code'),
                'selectCopy': t('選択してコピー', 'Select and copy'),
                'selectCopyLabel': t(
                  'コードを選択してコピーしてください',
                  'Select the code and copy it',
                ),
              }).replaceAll('<', r'\u003c'),
            ),
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

Component docsSidebar(SiteLocale locale, String active) {
  final t = locale.text;
  final localPath = locale.path;
  return el(
    'div',
    cls: 'd-sidebar-content',
    children: [
      el(
        'a',
        cls: 'd-docs-home',
        attrs: {'href': localPath('/docs/')},
        children: [
          el('span', cls: 'd-square-logo', text: 'g.'),
          el('span', text: t('ドキュメント', 'Documentation')),
          el('span', cls: 'd-small-tag', text: 'DART'),
        ],
      ),
      el(
        'nav',
        attrs: {'aria-label': t('ドキュメント', 'Documentation')},
        children: [
          for (final group in docsNavigation(locale))
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
                      if (item.path == localPath('/docs/quickstart/'))
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
          docLines(
            'p',
            text: t(
              'Flutter & Dartのための、\nオープンソースCI。',
              'Open-source CI\nfor Flutter & Dart.',
            ),
          ),
          el(
            'a',
            attrs: {'href': 'https://github.com/openci-org/openci'},
            children: [
              docsIcon('github'),
              el('span', text: t('GitHubで見る', 'View on GitHub')),
              docsIcon('external'),
            ],
          ),
        ],
      ),
    ],
  );
}

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
