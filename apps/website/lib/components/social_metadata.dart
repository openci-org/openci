import 'package:jaspr/server.dart';

import '../l10n/site_locale.dart';
import 'html.dart';

const siteOrigin = 'https://genuineci.com';
String siteTitle(SiteLocale locale) => locale.text(
  'GenuineCI — Flutter & Dartに、本物のCIを。',
  'GenuineCI — Real CI for Flutter & Dart.',
);
String siteDescription(SiteLocale locale) => locale.text(
  'Dartで書かれたFlutter & Dart専用のオープンソースCI。ワークフローもDartで定義。Apple Silicon M1〜M4に対応し、セルフホストも可能です。',
  'Open-source CI for Flutter & Dart, built in Dart. Write workflows in Dart, run on Apple Silicon M1–M4, and self-host on your own machines.',
);
const releaseImagePath = '/ogp/v2-1-0.jpg?v=2';
String releaseImageAlt(SiteLocale locale) => locale.text(
  'GenuineCI v2.1.0 is here. — 黄色い背景に黒い文字のリリースバナー',
  'GenuineCI v2.1.0 is here. — Black lettering on a yellow release banner',
);

Component socialMetadata({
  required String title,
  required String description,
  required String path,
  required Map<SiteLocale, String> translations,
  String imagePath = releaseImagePath,
  String? imageAlt,
  String type = 'website',
  String? section,
}) {
  final locale = SiteLocale.fromPath(path);
  imageAlt ??= releaseImageAlt(locale);
  final origin = Uri.parse(siteOrigin);
  final url = origin.resolve(path).toString();
  final imageUrl = origin.resolve(imagePath).toString();
  final properties = {
    'og:title': title,
    'og:type': type,
    'og:url': url,
    'og:description': description,
    'og:site_name': 'GenuineCI',
    'og:locale': locale.ogLocale,
    'og:image': imageUrl,
    'og:image:type': 'image/jpeg',
    'og:image:width': '1200',
    'og:image:height': '630',
    'og:image:alt': imageAlt,
    if (type == 'article' && section != null) 'article:section': section,
  };
  return Component.fragment([
    Document.html(attributes: {'lang': locale.name}),
    Document.head(
      title: title,
      meta: {
        'description': description,
        'twitter:card': 'summary_large_image',
        'twitter:title': title,
        'twitter:description': description,
        'twitter:image': imageUrl,
        'twitter:image:alt': imageAlt,
      },
      children: [
        el(
          'link',
          id: 'canonical-url',
          attrs: {'rel': 'canonical', 'href': url},
        ),
        for (final translation in translations.entries)
          el(
            'link',
            id: 'alternate-${translation.key.name}',
            attrs: {
              'rel': 'alternate',
              'hreflang': translation.key.name,
              'href': origin.resolve(translation.value).toString(),
            },
          ),
        if (translations[SiteLocale.en] case final defaultPath?)
          el(
            'link',
            id: 'alternate-default',
            attrs: {
              'rel': 'alternate',
              'hreflang': 'x-default',
              'href': origin.resolve(defaultPath).toString(),
            },
          ),
        for (final property in properties.entries)
          el(
            'meta',
            id: 'meta-${property.key}',
            attrs: {'property': property.key, 'content': property.value},
          ),
      ],
    ),
  ]);
}
