import 'package:genuineci_website/models/blog_post.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:test/test.dart';

void main() {
  test('new Markdown articles enter the blog in newest-first order', () {
    final posts = postsFromPages([
      _page('/blog/older', date: '2026-09-01'),
      _page('/blog'),
      _page('/about'),
      _page('/blog/newer', date: '2026-10-02'),
    ]);

    expect(posts.map((post) => post.url), ['/blog/newer/', '/blog/older/']);
  });

  test('articles published on the same date have a stable order', () {
    final posts = postsFromPages([
      _page('/blog/b', date: '2026-10-02'),
      _page('/blog/a', date: '2026-10-02'),
    ]);

    expect(posts.map((post) => post.url), ['/blog/a/', '/blog/b/']);
  });

  test('an empty blog has no featured article', () {
    expect(postsFromPages([_page('/blog')]), isEmpty);
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
