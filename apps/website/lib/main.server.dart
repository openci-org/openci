import 'dart:convert';
import 'dart:io';

import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/html.dart';
import 'pages/blog_page.dart';
import 'pages/landing_page.dart';

void main() {
  Jaspr.initializeApp();
  final favicon = base64Encode(File('web/favicon.png').readAsBytesSync());
  runApp(
    Document(
      title: 'GenuineCI — Flutter & Dartに、本物のCIを。',
      lang: 'ja',
      base: null,
      meta: {
        'description': 'Dartで書かれたFlutter & Dart専用のオープンソースCI。ワークフローもDartで定義。Apple Silicon M1〜M4に対応し、セルフホストも可能です。',
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
              '${File('web/site.css').readAsStringSync()}\n${File('web/blog.css').readAsStringSync()}',
            ),
          ],
        ),
      ],
      body: el(
        'div',
        children: [
          Router(
            routes: [
              Route(
                path: '/',
                builder: (context, state) => const LandingPage(),
              ),
              Route(
                path: '/blog',
                title: 'Journal — GenuineCI Blog',
                builder: (context, state) => const BlogPage(),
              ),
              for (final post in blogPosts)
                Route(
                  path: post.path,
                  title: '${post.title.replaceAll('\n', '')} — GenuineCI Blog',
                  builder: (context, state) => BlogArticlePage(post),
                ),
            ],
          ),
          el(
            'script',
            children: [
              RawText(
                '${File('web/site.js').readAsStringSync()}\n${File('web/blog.js').readAsStringSync()}',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
