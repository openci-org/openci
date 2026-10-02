import 'package:jaspr/server.dart';

import 'html.dart';

const siteOrigin = 'https://genuineci.com';
const siteTitle = 'GenuineCI — Flutter & Dartに、本物のCIを。';
const siteDescription =
    'Dartで書かれたFlutter & Dart専用のオープンソースCI。ワークフローもDartで定義。Apple Silicon M1〜M4に対応し、セルフホストも可能です。';
const releaseImagePath = '/ogp/v2-1-0.jpg?v=2';
const releaseImageAlt = 'GenuineCI v2.1.0 is here. — 黄色い背景に黒い文字のリリースバナー';

Component socialMetadata({
  required String title,
  required String description,
  required String path,
  String imagePath = releaseImagePath,
  String imageAlt = releaseImageAlt,
  String type = 'website',
  String? section,
}) {
  final origin = Uri.parse(siteOrigin);
  final url = origin.resolve(path).toString();
  final imageUrl = origin.resolve(imagePath).toString();
  final properties = {
    'og:title': title,
    'og:type': type,
    'og:url': url,
    'og:description': description,
    'og:site_name': 'GenuineCI',
    'og:locale': 'ja_JP',
    'og:image': imageUrl,
    'og:image:type': 'image/jpeg',
    'og:image:width': '1200',
    'og:image:height': '630',
    'og:image:alt': imageAlt,
    if (type == 'article' && section != null) 'article:section': section,
  };
  return Document.head(
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
      for (final property in properties.entries)
        el(
          'meta',
          id: 'meta-${property.key}',
          attrs: {'property': property.key, 'content': property.value},
        ),
    ],
  );
}
