import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

import '../components/html.dart';
import '../components/language_switcher.dart';
import '../components/social_metadata.dart';
import '../l10n/localized_component.dart';
import '../l10n/site_locale.dart';
import '../models/blog_post.dart';
import '../pages/blog_page.dart';

class BlogIndexLayout implements PageLayout {
  const BlogIndexLayout();

  @override
  String get name => 'blog-index';

  @override
  Component buildLayout(Page page, Component child) => BlogPage(page);
}

class BlogArticleLayout implements PageLayout {
  const BlogArticleLayout();

  @override
  String get name => 'blog-article';

  @override
  Component buildLayout(Page page, Component child) =>
      BlogArticlePage(page, child);
}

class BlogArticlePage extends LocalizedComponent {
  BlogArticlePage(this.page, this.content, {super.key})
    : super(SiteLocale.fromPath(page.url));

  final Page page;
  final Component content;

  @override
  Component build(BuildContext context) {
    final post = BlogPost(page);
    final translations = availableTranslations(
      page.url,
      context.pages.map((p) => p.url),
    );
    final blogPosts = postsFromPages(context.pages, locale);
    final index = blogPosts.indexWhere((item) => item.url == post.url);
    final nextPost = blogPosts.length > 1
        ? blogPosts[(index + 1) % blogPosts.length]
        : null;
    return el(
      'div',
      cls: 'journal-page article-page',
      children: [
        socialMetadata(
          title: post.pageTitle,
          description: post.summary,
          path: post.url,
          translations: translations,
          imagePath: post.imagePath,
          imageAlt: post.imageAlt,
          type: 'article',
          section: post.category,
        ),
        link(t('本文へスキップ', 'Skip to content'), '#main', cls: 'skip-link'),
        languageSwitcher(locale, translations),
        blogHeader(locale),
        el(
          'main',
          id: 'main',
          children: [
            el(
              'article',
              children: [
                el(
                  'div',
                  cls: 'wrap article-masthead',
                  children: [
                    link(
                      t('← ブログ一覧', '← Back to the blog'),
                      localPath('/blog/'),
                      cls: 'back-to-blog',
                    ),
                    postMeta(post),
                    el('h1', text: post.title),
                    el('p', cls: 'article-lead', text: post.summary),
                    el(
                      'div',
                      cls: 'article-byline',
                      children: [
                        el(
                          'span',
                          cls: 'author-monogram',
                          text: 'g',
                          attrs: {'aria-hidden': 'true'},
                        ),
                        el('span', text: post.author),
                      ],
                    ),
                  ],
                ),
                el(
                  'div',
                  cls: 'wrap article-cover-wrap',
                  children: [postCover(post, featured: true)],
                ),
                el(
                  'div',
                  cls: 'wrap article-layout',
                  children: [
                    el(
                      'aside',
                      cls: 'article-sidebar',
                      children: [
                        el(
                          'nav',
                          attrs: {'aria-label': t('記事の目次', 'Article contents')},
                          children: [
                            el(
                              'p',
                              cls: 'toc-heading',
                              text: 'IN THIS ARTICLE',
                            ),
                            if (page.data['toc'] case TableOfContents toc)
                              toc.build(),
                          ],
                        ),
                        el(
                          'p',
                          cls: 'article-aside-note',
                          text: t(
                            'Flutter & Dartのために。\nDartでつくられた、\nオープンソースのCI。',
                            'For Flutter & Dart.\nBuilt in Dart.\nOpen-source CI.',
                          ),
                        ),
                      ],
                    ),
                    el(
                      'div',
                      cls: 'article-body',
                      children: [
                        content,
                        el(
                          'div',
                          cls: 'article-endmark',
                          text: 'g.',
                          attrs: {'aria-hidden': 'true'},
                        ),
                        link(
                          t('GenuineCI を詳しく見る', 'Explore GenuineCI'),
                          localPath('/'),
                          cls: 'text-link',
                          arrow: 'arrow',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (nextPost != null)
              el(
                'section',
                cls: 'wrap article-next',
                attrs: {'aria-label': t('次の記事', 'Next article')},
                children: [
                  el('p', cls: 'eyebrow', text: 'READ NEXT'),
                  el(
                    'a',
                    attrs: {'href': nextPost.url},
                    children: [
                      el('h2', text: nextPost.plainTitle),
                      icon('arrow'),
                    ],
                  ),
                  link(
                    t('すべての記事を見る', 'View all articles'),
                    localPath('/blog/'),
                    cls: 'back-to-blog',
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
