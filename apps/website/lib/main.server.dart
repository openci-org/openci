import 'dart:convert';
import 'dart:io';

import 'package:jaspr/dom.dart' show Color, FontFamily, RawText;
import 'package:jaspr/server.dart';
import 'package:jaspr_content/components/code_block.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/html.dart';
import 'components/docs_code_block.dart';
import 'components/plain_code_block.dart';
import 'components/social_metadata.dart';
import 'content/heading_ids_extension.dart';
import 'layouts/blog_layout.dart';
import 'layouts/docs_layout.dart';
import 'main.server.options.dart';
import 'pages/landing_page.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions, useIsolates: false);
  final favicon = base64Encode(File('web/favicon.png').readAsBytesSync());
  runApp(
    Document(
      title: siteTitle,
      lang: 'ja',
      base: null,
      meta: {
        'description': siteDescription,
        'theme-color': '#fffb00',
        'robots': 'noindex, nofollow',
      },
      head: [
        el(
          'link',
          attrs: {
            'rel': 'icon',
            'type': 'image/png',
            'href': 'data:image/png;base64,$favicon',
          },
        ),
        el(
          'style',
          children: [
            RawText(
              '${File('web/site.css').readAsStringSync()}\n${File('web/blog.css').readAsStringSync()}\n${File('web/docs.css').readAsStringSync()}',
            ),
          ],
        ),
      ],
      body: el(
        'div',
        children: [
          const Document.html(
            attributes: {
              'prefix':
                  'og: https://ogp.me/ns# article: https://ogp.me/ns/article#',
            },
          ),
          ContentApp.custom(
            loaders: [FilesystemLoader('content')],
            eagerlyLoadAllPages: true,
            configResolver: (source) => PageConfig(
              parsers: [const MarkdownParser()],
              extensions: [
                const HeadingIdsExtension(),
                const TableOfContentsExtension(),
                HeadingAnchorsExtension(),
              ],
              components: source.path.startsWith('docs/')
                  ? [const DocsCodeBlock()]
                  : [const PlainCodeBlock(), CodeBlock()],
              layouts: [
                const BlogArticleLayout(),
                const BlogIndexLayout(),
                const GenuineDocsLayout(),
              ],
              theme: ContentTheme(
                primary: const Color('#141414'),
                background: const Color('#ffffff'),
                text: const Color('#141414'),
                font: FontFamily.variable('--font'),
                codeFont: FontFamily.variable('--mono'),
              ),
            ),
            routerBuilder: (routes) => Router(
              routes: [
                Route(
                  path: '/',
                  builder: (context, state) => const LandingPage(),
                ),
                for (final loaderRoutes in routes) ...loaderRoutes,
              ],
            ),
          ),
          el(
            'script',
            children: [
              RawText(
                '${File('web/site.js').readAsStringSync()}\n${File('web/blog.js').readAsStringSync()}\n${File('web/docs.js').readAsStringSync()}',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
