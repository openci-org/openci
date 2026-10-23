import 'dart:convert';
import 'dart:io';

import 'package:genuineci_website/l10n/site_locale.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:test/test.dart';

void main() {
  for (final locale in SiteLocale.values) {
    group(locale.name, () {
      final marketingRoutes = [
        '/',
        '/blog/',
        '/blog/v2-1-0/',
        '/blog/v2-2-0/',
        '/blog/v2-3-0/',
      ].map(locale.path).toList();
      final docsRoutes = [
        '/docs/',
        '/docs/quickstart/',
        '/docs/workflows/',
        '/docs/triggers/',
        '/docs/flutter/',
        '/docs/secrets/',
        '/docs/cli/',
        '/docs/self-hosting/',
      ].map(locale.path).toList();
      final routes = [...marketingRoutes, ...docsRoutes];
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
          expect(page.querySelector('html')!.attributes['lang'], locale.name);
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
          final ids = page
              .querySelectorAll('[id]')
              .map((element) => element.id);
          expect(ids.toSet(), hasLength(ids.length));
        });
      }

      test('all site links resolve to generated pages and existing anchors', () {
        for (final entry in pages.entries) {
          for (final anchor in entry.value.querySelectorAll('a[href]')) {
            final href = anchor.attributes['href']!;
            final uri = Uri.parse(
              'https://website.test${entry.key}',
            ).resolve(href);
            if (uri.host != 'website.test') continue;
            final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
            final file = File('build/jaspr${path}index.html');
            final destination =
                pages[path] ??
                (file.existsSync() ? parse(file.readAsStringSync()) : null);
            expect(
              destination,
              isNotNull,
              reason: '${entry.key} links to $href',
            );
            if (uri.fragment.isNotEmpty) {
              // Numeric IDs are valid HTML but need escaping in CSS selectors.
              expect(
                destination!
                    .querySelectorAll('[id]')
                    .map((element) => element.id),
                contains(Uri.decodeComponent(uri.fragment)),
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
        final code = pages[locale.path('/blog/v2-1-0/')]!.querySelector(
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
        final article = pages[locale.path('/blog/v2-1-0/')]!;
        final headings = article.querySelectorAll('.article-body .content h2');
        final toc = article.querySelectorAll('.article-sidebar nav a');
        expect(headings, isNotEmpty);
        for (final heading in headings) {
          expect(heading.id, isNotEmpty);
        }
        expect(
          toc.map(
            (anchor) => Uri.decodeComponent(
              Uri.parse(anchor.attributes['href']!).fragment,
            ),
          ),
          headings.map((heading) => heading.id),
        );
        expect(
          toc.map((anchor) => anchor.text),
          headings.map((heading) => heading.querySelector('span')!.text),
        );
      });

      test('Dart and terminal code blocks retain their copy controls', () {
        final article = pages[locale.path('/blog/v2-1-0/')]!;
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
        for (final route in marketingRoutes) {
          final (version, imagePath) = switch (logicalPath(route)) {
            '/blog/v2-3-0/' => ('v2.3.0', '/ogp/v2-3-0.jpg'),
            '/blog/v2-2-0/' => ('v2.2.0', '/ogp/v2-2-0.jpg'),
            _ => ('v2.1.0', '/ogp/v2-1-0.jpg?v=2'),
          };
          final imageUrl = 'https://genuineci.com$imagePath';
          final page = pages[route]!;
          String content(String selector) {
            final elements = page.querySelectorAll(selector);
            expect(elements, hasLength(1), reason: '$route: $selector');
            return elements.single.attributes['content']!;
          }

          final properties = page
              .querySelectorAll('meta[property]')
              .map((element) => element.attributes['property']);
          expect(properties.toSet(), hasLength(properties.length));
          final title = page.querySelector('title')!.text;
          final description = content('meta[name="description"]');
          final url = 'https://genuineci.com$route';
          expect(content('meta[property="og:title"]'), title);
          expect(content('meta[property="og:description"]'), description);
          expect(content('meta[property="og:url"]'), url);
          expect(
            page.querySelector('link[rel="canonical"]')!.attributes['href'],
            url,
          );
          expect(
            content('meta[property="og:type"]'),
            logicalPath(route).startsWith('/blog/v') ? 'article' : 'website',
          );
          expect(content('meta[property="og:image"]'), imageUrl);
          expect(content('meta[property="og:image:type"]'), 'image/jpeg');
          expect(content('meta[property="og:image:width"]'), '1200');
          expect(content('meta[property="og:image:height"]'), '630');
          expect(content('meta[property="og:image:alt"]'), contains(version));
          expect(content('meta[property="og:locale"]'), locale.ogLocale);
          expect(content('meta[name="twitter:card"]'), 'summary_large_image');
          expect(content('meta[name="twitter:title"]'), title);
          expect(content('meta[name="twitter:description"]'), description);
          expect(content('meta[name="twitter:image"]'), imageUrl);
          expect(content('meta[name="twitter:image:alt"]'), contains(version));
        }
        expect(
          File('build/jaspr/ogp/v2-1-0.jpg').readAsBytesSync(),
          File('web/ogp/v2-1-0.jpg').readAsBytesSync(),
        );
        expect(
          File('build/jaspr/ogp/v2-2-0.jpg').readAsBytesSync(),
          File('web/ogp/v2-2-0.jpg').readAsBytesSync(),
        );
        expect(
          File('build/jaspr/ogp/v2-3-0.jpg').readAsBytesSync(),
          File('web/ogp/v2-3-0.jpg').readAsBytesSync(),
        );
      });

      test('Docs search indexes every guide and its Markdown content', () {
        for (final route in docsRoutes) {
          final page = pages[route]!;
          final index =
              jsonDecode(
                    page.getElementById('docs-search-data')!.text,
                  )
                  as List<dynamic>;
          expect(
            index.map((entry) => (entry as Map<String, dynamic>)['url']),
            unorderedEquals(docsRoutes),
          );
          for (final entry in index.cast<Map<String, dynamic>>()) {
            expect(entry['title'], isNotEmpty);
            expect(entry['description'], isNotEmpty);
          }
          final quickstart = index.cast<Map<String, dynamic>>().singleWhere(
            (entry) => entry['url'] == locale.path('/docs/quickstart/'),
          );
          expect(quickstart['body'], contains('OpenCI.init'));
        }
      });

      test('Docs code blocks offer Light, Dark, and copy controls', () {
        for (final route in docsRoutes) {
          final blocks = pages[route]!.querySelectorAll('.d-code-surface');
          if (logicalPath(route) == '/docs/quickstart/' ||
              logicalPath(route) == '/docs/') {
            expect(blocks, isNotEmpty);
          }
          for (final block in blocks) {
            final theme = block.attributes['data-code-theme'];
            final buttons = block.querySelectorAll('[data-code-theme-choice]');
            expect(
              buttons.map(
                (button) => button.attributes['data-code-theme-choice'],
              ),
              ['light', 'dark'],
            );
            expect(
              buttons
                  .where(
                    (button) => button.attributes['aria-pressed'] == 'true',
                  )
                  .single
                  .attributes['data-code-theme-choice'],
              theme,
            );
            expect(
              block.querySelector(
                '[aria-label="${locale.text('コードをコピー', 'Copy code')}"]',
              ),
              isNotNull,
            );
            expect(block.querySelector('pre code')!.text.trim(), isNotEmpty);
          }
        }
      });

      test('the blog contains the release article without sample content', () {
        final blog = pages[locale.path('/blog/')]!;
        final article = pages[locale.path('/blog/v2-1-0/')]!;
        expect(blog.querySelectorAll('[data-article-category]'), hasLength(3));
        expect(blog.querySelector('[data-article-count]')!.text, '03 ARTICLES');
        expect(
          article.querySelector('time')!.attributes['datetime'],
          '2026-10-02',
        );
        expect(
          article.querySelector('.article-next a')!.attributes['href'],
          locale.path('/blog/v2-3-0/'),
        );
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
          expect(
            File(
              'build/jaspr/${locale.name}/blog/$slug/index.html',
            ).existsSync(),
            isFalse,
          );
        }
        for (final page in [blog, article]) {
          expect(page.body!.text, isNot(contains('サンプル')));
          expect(page.body!.text, isNot(contains('DESIGN SAMPLE')));
        }
      });
      test(
        'language links and metadata pair the same page in both languages',
        () {
          for (final entry in pages.entries) {
            final page = entry.value;
            final alternates = page.querySelectorAll(
              'link[rel="alternate"][hreflang]',
            );
            expect(alternates, hasLength(3));
            for (final language in SiteLocale.values) {
              final translatedPath = language.path(entry.key);
              expect(
                page
                    .querySelector('link[hreflang="${language.name}"]')!
                    .attributes['href'],
                'https://genuineci.com$translatedPath',
              );
              final link = page.querySelector(
                '.language-switcher a[hreflang="${language.name}"]',
              )!;
              expect(link.attributes['href'], translatedPath);
              expect(link.attributes['lang'], language.name);
              expect(
                link.attributes['aria-current'],
                language == locale ? 'page' : null,
              );
              final translated = parse(
                File(
                  'build/jaspr${translatedPath}index.html',
                ).readAsStringSync(),
              );
              expect(
                translated
                    .querySelector('link[hreflang="${locale.name}"]')!
                    .attributes['href'],
                'https://genuineci.com${entry.key}',
              );
            }
            expect(
              page
                  .querySelector('link[hreflang="x-default"]')!
                  .attributes['href'],
              'https://genuineci.com${SiteLocale.en.path(entry.key)}',
            );
            expect(
              page.querySelector('link[rel="canonical"]')!.attributes['href'],
              'https://genuineci.com${entry.key}',
            );
          }
        },
      );

      test('internal navigation stays in the chosen language', () {
        for (final entry in pages.entries) {
          for (final link in entry.value.querySelectorAll('a[href]')) {
            if (link.attributes.containsKey('data-language-link')) continue;
            final uri = Uri.parse(
              'https://website.test${entry.key}',
            ).resolve(link.attributes['href']!);
            if (uri.host == 'website.test') {
              expect(
                uri.path,
                startsWith('/${locale.name}/'),
                reason: '${entry.key}: ${link.outerHtml}',
              );
            }
          }
        }
      });

      test('English content contains no untranslated Japanese UI or prose', () {
        if (locale != SiteLocale.en) return;
        for (final entry in pages.entries) {
          final body = entry.value.body!.clone(true);
          for (final excluded in body.querySelectorAll(
            'script, style, .language-switcher',
          )) {
            excluded.remove();
          }
          expect(
            RegExp(r'[\u3040-\u30ff\u3400-\u9fff]').hasMatch(body.text),
            isFalse,
            reason: entry.key,
          );
          for (final element in body.querySelectorAll(
            '[aria-label], [placeholder]',
          )) {
            expect(
              RegExp(r'[\u3040-\u30ff\u3400-\u9fff]').hasMatch(
                '${element.attributes['aria-label']}${element.attributes['placeholder']}',
              ),
              isFalse,
              reason: element.outerHtml,
            );
          }
        }
      });
    });
  }

  test('translations retain code examples and pricing values', () {
    final japanese = Directory('content/ja')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.md'));
    final code = RegExp(r'```[^\n]*\n([\s\S]*?)```');
    for (final file in japanese) {
      final english = File(
        file.path.replaceFirst('content/ja/', 'content/en/'),
      );
      // Newly published articles may not have a translation yet.
      if (!english.existsSync()) continue;
      expect(
        code.allMatches(english.readAsStringSync()).map((m) => m.group(1)),
        code.allMatches(file.readAsStringSync()).map((m) => m.group(1)),
        reason: file.path,
      );
    }
    final ja = parse(File('build/jaspr/ja/index.html').readAsStringSync());
    final en = parse(File('build/jaspr/en/index.html').readAsStringSync());
    expect(
      en.querySelectorAll('.pricing-price strong').map((e) => e.text),
      ja.querySelectorAll('.pricing-price strong').map((e) => e.text),
    );
    expect(
      en
          .querySelectorAll('.pricing-allowance strong')
          .map((e) => e.text.replaceAll(RegExp(r'[^0-9]'), '')),
      ja
          .querySelectorAll('.pricing-allowance strong')
          .map((e) => e.text.replaceAll(RegExp(r'[^0-9]'), '')),
    );
    expect(en.getElementById('pricing')!.text, contains('168 hours'));
    expect(ja.getElementById('pricing')!.text, contains('168時間'));
  });
}
