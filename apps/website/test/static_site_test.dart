import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  const routes = [
    '/',
    '/blog/',
    '/blog/why/',
    '/blog/workflows/',
    '/blog/self-host/',
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
        final destination = pages[uri.path];
        expect(destination, isNotNull, reason: '${entry.key} links to $href');
        if (uri.fragment.isNotEmpty) {
          expect(
            destination!.getElementById(uri.fragment),
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
    final code = pages['/blog/workflows/']!.querySelector(
      '.article-code code',
    )!;
    expect(
      const LineSplitter().convert(code.text),
      [
        "await ci.run('flutter pub get');",
        'await ci.flutter.staticAnalysis();',
        'await ci.flutter.unitTests();',
      ],
    );
  });
}
