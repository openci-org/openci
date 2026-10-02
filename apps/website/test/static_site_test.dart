import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  const routes = [
    '/',
    '/blog/',
    '/blog/v2-1-0/',
  ];
  final pages = <String, Document>{};

  setUpAll(() {
    for (final route in routes) {
      final file = File('build/jaspr${route}index.html');
      if (!file.existsSync()) {
        fail('Missing $route. Run jaspr build before dart test.');
      }
      pages[route] = parse(file.readAsStringSync());
    }
  });

  for (final route in routes) {
    test('$route renders the site with its supplied favicon', () {
      final page = pages[route]!;
      expect(page.querySelectorAll('main'), hasLength(1));
      expect(page.querySelectorAll('h1'), hasLength(1));
      expect(page.querySelector('title')!.text, contains('GenuineCI'));
      expect(page.querySelector('html')!.attributes['lang'], 'ja');
      expect(
        page.querySelector('meta[name="robots"]')!.attributes['content'],
        'noindex, nofollow',
      );
      final favicon = page.querySelector('link[rel="icon"]')!;
      expect(favicon.attributes['type'], 'image/png');
      expect(
        Uri.parse(favicon.attributes['href']!).data!.contentAsBytes(),
        File('web/favicon.png').readAsBytesSync(),
      );
      final ids = page.querySelectorAll('[id]').map((element) => element.id);
      expect(ids.toSet(), hasLength(ids.length));
    });
  }

  test('all site links resolve to generated pages and existing anchors', () {
    for (final entry in pages.entries) {
      for (final anchor in entry.value.querySelectorAll('a[href]')) {
        final href = anchor.attributes['href']!;
        final uri = Uri.parse('https://website.test${entry.key}').resolve(href);
        if (uri.host != 'website.test') continue;
        final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
        final destination = pages[path];
        expect(destination, isNotNull, reason: '${entry.key} links to $href');
        if (uri.fragment.isNotEmpty) {
          expect(
            destination!.getElementById(Uri.decodeComponent(uri.fragment)),
            isNotNull,
            reason: '${entry.key} links to missing anchor $href',
          );
        }
      }
    }
  });

  test('article titles and code survive static rendering', () {
    final titles = pages.values.map(
      (page) => page.querySelector('title')!.text,
    );
    expect(titles.toSet(), hasLength(routes.length));
    final code = pages['/blog/v2-1-0/']!.querySelector(
      '.article-body .code-block code',
    )!;
    expect(
      const LineSplitter().convert(code.text),
      [
        "await ci.flutter.buildApk(flavor: 'staging');",
        "await ci.flutter.buildAab(flavor: 'production');",
      ],
    );
  });

  test('Markdown headings supply the article table of contents', () {
    final article = pages['/blog/v2-1-0/']!;
    final headings = article.querySelectorAll('.article-body .content h2');
    final toc = article.querySelectorAll('.article-sidebar nav a');
    expect(headings, isNotEmpty);
    for (final heading in headings) {
      expect(heading.id, isNotEmpty);
    }
    expect(
      toc.map(
        (anchor) =>
            Uri.decodeComponent(Uri.parse(anchor.attributes['href']!).fragment),
      ),
      headings.map((heading) => heading.id),
    );
    expect(
      toc.map((anchor) => anchor.text),
      headings.map((heading) => heading.querySelector('span')!.text),
    );
  });

  test('Dart and terminal code blocks retain their copy controls', () {
    final article = pages['/blog/v2-1-0/']!;
    final blocks = article.querySelectorAll('.article-body .code-block');
    expect(blocks, hasLength(3));
    for (final block in blocks) {
      expect(block.querySelector('button'), isNotNull);
    }
    expect(
      const LineSplitter().convert(blocks.last.querySelector('code')!.text),
      ['openci switch team', 'openci list secrets', 'openci sync secrets'],
    );
    expect(blocks.first.querySelector('code span'), isNotNull);
  });

  test('interactive client bundle is generated and included', () {
    expect(File('build/jaspr/main.client.dart.js').existsSync(), isTrue);
    for (final page in pages.values) {
      expect(
        page.querySelector('script[src="/main.client.dart.js"]'),
        isNotNull,
      );
    }
  });

  test('social cards use the public URL and the release banner', () {
    const imageUrl = 'https://genuineci.com/ogp/v2-1-0.jpg?v=2';
    for (final entry in pages.entries) {
      final page = entry.value;
      String content(String selector) {
        final elements = page.querySelectorAll(selector);
        expect(elements, hasLength(1), reason: '${entry.key}: $selector');
        return elements.single.attributes['content']!;
      }

      final properties = page
          .querySelectorAll('meta[property]')
          .map((element) => element.attributes['property']);
      expect(properties.toSet(), hasLength(properties.length));
      final title = page.querySelector('title')!.text;
      final description = content('meta[name="description"]');
      final url = 'https://genuineci.com${entry.key}';
      expect(content('meta[property="og:title"]'), title);
      expect(content('meta[property="og:description"]'), description);
      expect(content('meta[property="og:url"]'), url);
      expect(
        page.querySelector('link[rel="canonical"]')!.attributes['href'],
        url,
      );
      expect(
        content('meta[property="og:type"]'),
        entry.key == '/blog/v2-1-0/' ? 'article' : 'website',
      );
      expect(content('meta[property="og:image"]'), imageUrl);
      expect(content('meta[property="og:image:type"]'), 'image/jpeg');
      expect(content('meta[property="og:image:width"]'), '1200');
      expect(content('meta[property="og:image:height"]'), '630');
      expect(content('meta[property="og:image:alt"]'), contains('v2.1.0'));
      expect(content('meta[property="og:locale"]'), 'ja_JP');
      expect(content('meta[name="twitter:card"]'), 'summary_large_image');
      expect(content('meta[name="twitter:title"]'), title);
      expect(content('meta[name="twitter:description"]'), description);
      expect(content('meta[name="twitter:image"]'), imageUrl);
      expect(content('meta[name="twitter:image:alt"]'), contains('v2.1.0'));
    }
    expect(
      File('build/jaspr/ogp/v2-1-0.jpg').readAsBytesSync(),
      File('web/ogp/v2-1-0.jpg').readAsBytesSync(),
    );
  });

  test('the blog contains the release article without sample content', () {
    final blog = pages['/blog/']!;
    final article = pages['/blog/v2-1-0/']!;
    expect(blog.querySelectorAll('[data-article-category]'), hasLength(1));
    expect(blog.querySelector('[data-article-count]')!.text, '01 ARTICLE');
    expect(article.querySelector('time')!.attributes['datetime'], '2026-10-02');
    expect(article.querySelector('.article-next'), isNull);
    expect(
      article
          .querySelectorAll(
            '.article-body .content a[href^="https://github.com/openci-org/openci/"]',
          )
          .map(
            (anchor) => anchor.attributes['href'],
          ),
      [
        'https://github.com/openci-org/openci/releases/tag/v2.1.0',
        'https://github.com/openci-org/openci/compare/v2.0.0...v2.1.0',
      ],
    );
    for (final slug in ['why', 'workflows', 'self-host']) {
      expect(File('build/jaspr/blog/$slug/index.html').existsSync(), isFalse);
    }
    for (final page in [blog, article]) {
      expect(page.body!.text, isNot(contains('サンプル')));
      expect(page.body!.text, isNot(contains('DESIGN SAMPLE')));
    }
  });
}
