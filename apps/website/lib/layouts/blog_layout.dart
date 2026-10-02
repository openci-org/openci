import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

import '../components/html.dart';
import '../components/social_metadata.dart';
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

class BlogArticlePage extends StatelessComponent {
  const BlogArticlePage(this.page, this.content, {super.key});

  final Page page;
  final Component content;

  @override
  Component build(BuildContext context) {
    final post = BlogPost(page);
    final blogPosts = postsFromPages(context.pages);
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
          imagePath: post.imagePath,
          imageAlt: post.imageAlt,
          type: 'article',
          section: post.category,
        ),
        link('本文へスキップ', '#main', cls: 'skip-link'),
        blogHeader(),
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
                    link('← ブログ一覧', '/blog/', cls: 'back-to-blog'),
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
                          attrs: {'aria-label': '記事の目次'},
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
                          text: 'Flutter & Dartのために。\nDartでつくられた、\nオープンソースのCI。',
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
                          'GenuineCI を詳しく見る',
                          '/',
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
                attrs: {'aria-label': '次の記事'},
                children: [
                  el('p', cls: 'eyebrow', text: 'READ NEXT'),
                  el(
                    'a',
                    attrs: {'href': nextPost.url},
                    children: [
                      el('h2', text: nextPost.title.replaceAll('\n', '')),
                      icon('arrow'),
                    ],
                  ),
                  link('すべての記事を見る', '/blog/', cls: 'back-to-blog'),
                ],
              ),
          ],
        ),
        blogFooter(),
      ],
    );
  }
}
