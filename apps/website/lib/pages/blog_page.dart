import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

import '../components/html.dart';
import '../components/social_metadata.dart';
import '../models/blog_post.dart';

Component blogHeader() => el(
  'header',
  cls: 'site-header wrap blog-header',
  children: [
    link('GenuineCI', '/', cls: 'brand'),
    el(
      'nav',
      cls: 'blog-nav',
      attrs: {'aria-label': 'メインナビゲーション'},
      children: [
        link('プロダクト', '/', cls: 'blog-product-link'),
        link('Docs', '/docs/'),
        link('ワークフロー', '/#workflow', cls: 'blog-workflow-link'),
        el(
          'a',
          cls: 'nav-current',
          text: 'ブログ',
          attrs: {'href': '/blog/', 'aria-current': 'page'},
        ),
      ],
    ),
    link(
      'はじめる',
      '/#get-started',
      cls: 'button button-small button-dark',
      arrow: 'arrow',
    ),
  ],
);

Component blogFooter() => el(
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
            el('p', cls: 'eyebrow', text: 'BUILT IN DART. BUILT IN THE OPEN.'),
            el('h2', text: 'つくる人のための、\n本物のCI。'),
          ],
        ),
        link(
          'GenuineCI を知る',
          '/',
          cls: 'button button-dark',
          arrow: 'arrow',
        ),
      ],
    ),
    el(
      'div',
      cls: 'wrap journal-footer-bottom',
      children: [
        link('GenuineCI', '/', cls: 'brand'),
        el('span', text: '© 2026 GenuineCI'),
        link('ブログ一覧へ', '/blog/'),
      ],
    ),
  ],
);

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

class BlogPage extends StatelessComponent {
  const BlogPage(this.page, {super.key});

  final Page page;

  @override
  Component build(BuildContext context) {
    final blogPosts = postsFromPages(context.pages);
    return el(
      'div',
      cls: 'journal-page',
      children: [
        socialMetadata(
          title: page.data.page['title'] as String,
          description: page.data.page['description'] as String,
          path: '/blog/',
        ),
        link('本文へスキップ', '#main', cls: 'skip-link'),
        blogHeader(),
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
                        el('h2', text: 'つくる過程も、オープンに。'),
                        el(
                          'p',
                          text:
                              'Flutter & Dartと、本物のCIのこと。\nGenuineCIの考え方と開発の記録。',
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
                      el('span', text: '最新のリリースをチェック。'),
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
                            children: [Component.text('記事を読む'), icon('arrow')],
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
                    el('h2', id: 'articles-heading', text: 'すべての記事'),
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
                  attrs: {'role': 'group', 'aria-label': '記事をカテゴリで絞り込む'},
                  children: [
                    for (final category in [
                      'すべて',
                      ...blogPosts.map((post) => post.category).toSet(),
                    ])
                      el(
                        'button',
                        cls: 'filter-button',
                        text: category,
                        attrs: {
                          'type': 'button',
                          'data-category-filter': category,
                          'aria-pressed': category == 'すべて' ? 'true' : 'false',
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
                                      Component.text('記事を読む'),
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
        blogFooter(),
      ],
    );
  }
}
