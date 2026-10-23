import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

import '../components/html.dart';
import '../components/language_switcher.dart';
import '../components/social_metadata.dart';
import '../l10n/localized_component.dart';
import '../l10n/site_locale.dart';
import '../models/blog_post.dart';

Component blogHeader(SiteLocale locale) {
  final t = locale.text;
  final localPath = locale.path;
  return el(
    'header',
    cls: 'site-header wrap blog-header',
    children: [
      link('GenuineCI', localPath('/'), cls: 'brand'),
      el(
        'nav',
        cls: 'blog-nav',
        attrs: {'aria-label': t('メインナビゲーション', 'Main navigation')},
        children: [
          link(t('プロダクト', 'Product'), localPath('/'), cls: 'blog-product-link'),
          link('Docs', localPath('/docs/')),
          link(
            t('ワークフロー', 'Workflows'),
            localPath('/#workflow'),
            cls: 'blog-workflow-link',
          ),
          el(
            'a',
            cls: 'nav-current',
            text: t('ブログ', 'Blog'),
            attrs: {'href': localPath('/blog/'), 'aria-current': 'page'},
          ),
        ],
      ),
      link(
        t('はじめる', 'Get started'),
        localPath('/#get-started'),
        cls: 'button button-small button-dark',
        arrow: 'arrow',
      ),
    ],
  );
}

Component blogFooter(SiteLocale locale) {
  final t = locale.text;
  final localPath = locale.path;
  return el(
    'footer',
    cls: 'journal-footer',
    children: [
      el(
        'div',
        cls: 'wrap journal-footer-top',
        children: [
          el(
            'div',
            children: [
              el(
                'p',
                cls: 'eyebrow',
                text: 'BUILT IN DART. BUILT IN THE OPEN.',
              ),
              el(
                'h2',
                text: t('つくる人のための、\n本物のCI。', 'Real CI.\nFor people who build.'),
              ),
            ],
          ),
          link(
            t('GenuineCI を知る', 'Explore GenuineCI'),
            localPath('/'),
            cls: 'button button-dark',
            arrow: 'arrow',
          ),
        ],
      ),
      el(
        'div',
        cls: 'wrap journal-footer-bottom',
        children: [
          link('GenuineCI', localPath('/'), cls: 'brand'),
          el('span', text: '© 2026 GenuineCI'),
          link(t('ブログ一覧へ', 'Back to the blog'), localPath('/blog/')),
        ],
      ),
    ],
  );
}

Component postMeta(BlogPost post) => el(
  'div',
  cls: 'post-meta',
  children: [
    el('span', cls: 'post-category', text: post.category),
    el(
      'time',
      text: post.publishedAt.replaceAll('-', '.'),
      attrs: {'datetime': post.publishedAt},
    ),
    if (post.readTime case final readTime?) el('span', text: readTime),
  ],
);

Component postCover(BlogPost post, {bool featured = false}) => el(
  'div',
  cls: 'post-cover cover-release${featured ? ' cover-featured' : ''}',
  attrs: {'aria-hidden': 'true'},
  children: [
    el(
      'div',
      cls: 'cover-topline',
      children: [
        el('span', text: 'GenuineCI'),
        el('span', text: post.publishedAt.replaceAll('-', '.')),
      ],
    ),
    el(
      'div',
      cls: 'cover-message',
      children: [
        el('span', text: post.coverTitle),
        el('span', text: 'is here.'),
      ],
    ),
    el(
      'div',
      cls: 'cover-bottomline',
      children: [
        el('span', text: post.coverLabel),
        icon('arrow'),
      ],
    ),
  ],
);

class BlogPage extends LocalizedComponent {
  BlogPage(this.page, {super.key}) : super(SiteLocale.fromPath(page.url));

  final Page page;

  @override
  Component build(BuildContext context) {
    final translations = availableTranslations(
      page.url,
      context.pages.map((p) => p.url),
    );
    final blogPosts = postsFromPages(context.pages, locale);
    return el(
      'div',
      cls: 'journal-page',
      children: [
        socialMetadata(
          title: page.data.page['title'] as String,
          description: page.data.page['description'] as String,
          path: localPath('/blog/'),
          translations: translations,
        ),
        link(t('本文へスキップ', 'Skip to content'), '#main', cls: 'skip-link'),
        languageSwitcher(locale, translations),
        blogHeader(locale),
        el(
          'main',
          id: 'main',
          children: [
            el(
              'section',
              cls: 'wrap journal-hero',
              children: [
                el(
                  'div',
                  cls: 'journal-kicker',
                  children: [
                    el('span', text: 'THE GENUINECI BLOG'),
                  ],
                ),
                el(
                  'div',
                  cls: 'journal-title-row',
                  children: [
                    el(
                      'h1',
                      text: 'Journal',
                      children: [el('span', text: '.', cls: 'journal-dot')],
                    ),
                    el(
                      'div',
                      cls: 'journal-intro',
                      children: [
                        el(
                          'h2',
                          text: t('つくる過程も、オープンに。', 'Building in the open.'),
                        ),
                        el(
                          'p',
                          text: t(
                            'Flutter & Dartと、本物のCIのこと。\nGenuineCIの考え方と開発の記録。',
                            'Flutter, Dart, and real CI.\nIdeas and updates from GenuineCI.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (blogPosts.isNotEmpty)
              el(
                'section',
                cls: 'wrap featured-section',
                attrs: {'aria-labelledby': 'featured-label'},
                children: [
                  el(
                    'div',
                    cls: 'journal-section-label',
                    children: [
                      el('h2', id: 'featured-label', text: 'PICKUP'),
                      el(
                        'span',
                        text: t('最新のリリースをチェック。', 'Explore the latest release.'),
                      ),
                    ],
                  ),
                  el(
                    'a',
                    cls: 'featured-post',
                    attrs: {'href': blogPosts.first.url},
                    children: [
                      postCover(blogPosts.first, featured: true),
                      el(
                        'div',
                        cls: 'featured-copy',
                        children: [
                          postMeta(blogPosts.first),
                          el('h3', text: blogPosts.first.title),
                          el('p', text: blogPosts.first.summary),
                          el(
                            'span',
                            cls: 'article-read-link',
                            children: [
                              Component.text(t('記事を読む', 'Read article')),
                              icon('arrow'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            el(
              'section',
              cls: 'wrap journal-articles',
              attrs: {'aria-labelledby': 'articles-heading'},
              children: [
                el(
                  'div',
                  cls: 'articles-heading',
                  children: [
                    el(
                      'h2',
                      id: 'articles-heading',
                      text: t('すべての記事', 'All articles'),
                    ),
                    el(
                      'span',
                      cls: 'article-count',
                      text:
                          '${blogPosts.length.toString().padLeft(2, '0')} '
                          '${blogPosts.length == 1 ? 'ARTICLE' : 'ARTICLES'}',
                      attrs: {'data-article-count': '', 'aria-live': 'polite'},
                    ),
                  ],
                ),
                el(
                  'div',
                  cls: 'article-filters',
                  attrs: {
                    'role': 'group',
                    'aria-label': t(
                      '記事をカテゴリで絞り込む',
                      'Filter articles by category',
                    ),
                  },
                  children: [
                    for (final category in [
                      t('すべて', 'All'),
                      ...blogPosts.map((post) => post.category).toSet(),
                    ])
                      el(
                        'button',
                        cls: 'filter-button',
                        text: category,
                        attrs: {
                          'type': 'button',
                          'data-category-filter': category == t('すべて', 'All')
                              ? 'all'
                              : category,
                          'aria-pressed': category == t('すべて', 'All')
                              ? 'true'
                              : 'false',
                          'aria-controls': 'article-grid',
                        },
                      ),
                  ],
                ),
                el(
                  'div',
                  cls: 'article-grid',
                  id: 'article-grid',
                  children: [
                    for (final post in blogPosts)
                      el(
                        'article',
                        cls: 'post-card',
                        attrs: {'data-article-category': post.category},
                        children: [
                          el(
                            'a',
                            cls: 'post-card-link',
                            attrs: {'href': post.url},
                            children: [
                              postCover(post),
                              el(
                                'div',
                                cls: 'post-card-body',
                                children: [
                                  postMeta(post),
                                  el('h3', text: post.title),
                                  el('p', text: post.summary),
                                  el(
                                    'span',
                                    cls: 'card-read-link',
                                    children: [
                                      Component.text(
                                        t('記事を読む', 'Read article'),
                                      ),
                                      icon('arrow'),
                                    ],
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
            ),
          ],
        ),
        blogFooter(locale),
      ],
    );
  }
}
