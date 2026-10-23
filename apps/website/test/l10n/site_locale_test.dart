import 'package:genuineci_website/l10n/site_locale.dart';
import 'package:test/test.dart';

void main() {
  group('locale routing', () {
    test('explicit path chooses the language, with English as the default', () {
      expect(SiteLocale.fromPath('/'), SiteLocale.en);
      expect(SiteLocale.fromPath('/en/docs/'), SiteLocale.en);
      expect(SiteLocale.fromPath('/ja/docs/'), SiteLocale.ja);
      expect(SiteLocale.fromPath('ja/docs/index.md'), SiteLocale.ja);
      expect(SiteLocale.fromPath('/japanese/'), SiteLocale.en);
    });

    test('switches prefixes without losing queries or fragments', () {
      expect(
        SiteLocale.en.path('/ja/blog/v2-3-0/?from=docs#intro'),
        '/en/blog/v2-3-0/?from=docs#intro',
      );
      expect(SiteLocale.ja.path('/en/#pricing'), '/ja/#pricing');
      expect(SiteLocale.en.path('/docs'), '/en/docs/');
      expect(SiteLocale.en.path('/en/'), '/en/');
      expect(logicalPath('/ja/docs/cli/?q=secret'), '/docs/cli/');
    });

    test('leaves external links and assets on other hosts untouched', () {
      for (final url in [
        'https://dashboard.openci.org/',
        '//cdn.example.com/a.png',
        'mailto:m.aoki@openci.org',
      ]) {
        expect(SiteLocale.ja.path(url), url);
      }
    });

    test('only advertises existing counterpart pages', () {
      final pages = [
        '/en/blog',
        '/ja/blog',
        '/ja/blog/new',
        '/en/docs/cli',
        '/ja/docs/cli',
      ];
      expect(availableTranslations('/ja/blog/new/', pages), {
        SiteLocale.ja: '/ja/blog/new/',
      });
      expect(availableTranslations('/en/docs/cli/', pages), {
        SiteLocale.en: '/en/docs/cli/',
        SiteLocale.ja: '/ja/docs/cli/',
      });
      expect(availableTranslations('/en/missing/', pages), isEmpty);
    });
  });
}
