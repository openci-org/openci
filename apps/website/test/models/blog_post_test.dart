import 'package:genuineci_website/l10n/site_locale.dart';
import 'package:genuineci_website/models/blog_post.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:test/test.dart';

void main() {
  test('new Markdown articles enter the blog in newest-first order', () {
    final posts = postsFromPages([
      _page('/en/blog/older', date: '2026-09-01'),
      _page('/en/blog'),
      _page('/en/about'),
      _page('/en/blog/newer', date: '2026-10-02'),
      _page('/ja/blog/newest', date: '2026-10-23'),
    ], SiteLocale.en);

    expect(posts.map((post) => post.url), [
      '/en/blog/newer/',
      '/en/blog/older/',
    ]);
  });

  test('articles published on the same date have a stable order', () {
    final posts = postsFromPages([
      _page('/en/blog/b', date: '2026-10-02'),
      _page('/en/blog/a', date: '2026-10-02'),
    ], SiteLocale.en);

    expect(posts.map((post) => post.url), ['/en/blog/a/', '/en/blog/b/']);
  });

  test('an empty blog has no featured article', () {
    expect(postsFromPages([_page('/en/blog')], SiteLocale.en), isEmpty);
  });
}

Page _page(String url, {String? date}) => Page(
  path: '${url.substring(1)}.md',
  url: url,
  content: '',
  initialData: {
    'page': {'date': date},
  },
  config: const PageConfig(),
  loader: MemoryLoader(pages: []),
);
