import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';

import '../components/dart_code.dart';
import '../components/html.dart';
import '../components/social_metadata.dart';

class BlogPost {
  const BlogPost(
    this.slug,
    this.category,
    this.title,
    this.summary,
    this.publishedAt,
    this.readTime,
    this.coverLabel,
    this.coverTitle,
  );
  final String slug;
  final String category;
  final String title;
  final String summary;
  final String publishedAt;
  final String readTime;
  final String coverLabel;
  final String coverTitle;
  String get path => '/blog/$slug';
  String get url => '$path/';
  String get imagePath => '/ogp/$slug.jpg?v=2';
}

const blogPosts = [
  BlogPost(
    'v2-1-0',
    'リリース',
    'GenuineCI v2.1.0 を\nリリースしました。',
    'Android の APK・AAB ビルド、CLI のチーム切替、ワークフロー SDK の改善。v2.0.0 からの変更を紹介します。',
    '2026-10-02',
    '3 min read',
    'RELEASE NOTES',
    'v2.1.0',
  ),
];

Component blogHeader() => el(
  'header',
  cls: 'site-header wrap blog-header',
  children: [
    link('GenuineCI', '/', cls: 'brand'),
    el(
      'nav',
      cls: 'blog-nav',
      attrs: {'aria-label': 'メインナビゲーション'},
      children: [
        link('プロダクト', '/', cls: 'blog-product-link'),
        link('ワークフロー', '/#workflow', cls: 'blog-workflow-link'),
        el(
          'a',
          cls: 'nav-current',
          text: 'ブログ',
          attrs: {'href': '/blog/', 'aria-current': 'page'},
        ),
      ],
    ),
    link(
      'はじめる',
      '/#get-started',
      cls: 'button button-small button-dark',
      arrow: 'arrow',
    ),
  ],
);

Component blogFooter() => el(
  'footer',
  cls: 'journal-footer',
  children: [
    el(
      'div',
      cls: 'wrap journal-footer-top',
      children: [
        el(
          'div',
          children: [
            el('p', cls: 'eyebrow', text: 'BUILT IN DART. BUILT IN THE OPEN.'),
            el('h2', text: 'つくる人のための、\n本物のCI。'),
          ],
        ),
        link(
          'GenuineCI を知る',
          '/',
          cls: 'button button-dark',
          arrow: 'arrow',
        ),
      ],
    ),
    el(
      'div',
      cls: 'wrap journal-footer-bottom',
      children: [
        link('GenuineCI', '/', cls: 'brand'),
        el('span', text: '© 2026 GenuineCI'),
        link('ブログ一覧へ', '/blog/'),
      ],
    ),
  ],
);

Component postMeta(BlogPost post) => el(
  'div',
  cls: 'post-meta',
  children: [
    el('span', cls: 'post-category', text: post.category),
    el(
      'time',
      text: post.publishedAt.replaceAll('-', '.'),
      attrs: {'datetime': post.publishedAt},
    ),
    el('span', text: post.readTime),
  ],
);

Component postCover(BlogPost post, {bool featured = false}) => el(
  'div',
  cls: 'post-cover cover-release${featured ? ' cover-featured' : ''}',
  attrs: {'aria-hidden': 'true'},
  children: [
    el(
      'div',
      cls: 'cover-topline',
      children: [
        el('span', text: 'GenuineCI'),
        el('span', text: post.publishedAt.replaceAll('-', '.')),
      ],
    ),
    el(
      'div',
      cls: 'cover-message',
      children: [
        el('span', text: post.coverTitle),
        el('span', text: 'is here.'),
      ],
    ),
    el(
      'div',
      cls: 'cover-bottomline',
      children: [
        el('span', text: post.coverLabel),
        icon('arrow'),
      ],
    ),
  ],
);

class BlogPage extends StatelessComponent {
  const BlogPage({super.key});

  @override
  Component build(BuildContext context) => el(
    'div',
    cls: 'journal-page',
    children: [
      socialMetadata(
        title: 'Journal — GenuineCI Blog',
        description: 'GenuineCIのリリース情報と開発の記録。Flutter & DartのためのCIの最新情報をお届けします。',
        path: '/blog/',
      ),
      link('本文へスキップ', '#main', cls: 'skip-link'),
      blogHeader(),
      el(
        'main',
        id: 'main',
        children: [
          el(
            'section',
            cls: 'wrap journal-hero',
            children: [
              el(
                'div',
                cls: 'journal-kicker',
                children: [
                  el('span', text: 'THE GENUINECI BLOG'),
                ],
              ),
              el(
                'div',
                cls: 'journal-title-row',
                children: [
                  el(
                    'h1',
                    text: 'Journal',
                    children: [el('span', text: '.', cls: 'journal-dot')],
                  ),
                  el(
                    'div',
                    cls: 'journal-intro',
                    children: [
                      el('h2', text: 'つくる過程も、オープンに。'),
                      el(
                        'p',
                        text: 'Flutter & Dartと、本物のCIのこと。\nGenuineCIの考え方と開発の記録。',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          el(
            'section',
            cls: 'wrap featured-section',
            attrs: {'aria-labelledby': 'featured-label'},
            children: [
              el(
                'div',
                cls: 'journal-section-label',
                children: [
                  el('h2', id: 'featured-label', text: 'PICKUP'),
                  el('span', text: '最新のリリースをチェック。'),
                ],
              ),
              el(
                'a',
                cls: 'featured-post',
                attrs: {'href': blogPosts.first.url},
                children: [
                  postCover(blogPosts.first, featured: true),
                  el(
                    'div',
                    cls: 'featured-copy',
                    children: [
                      postMeta(blogPosts.first),
                      el('h3', text: blogPosts.first.title),
                      el('p', text: blogPosts.first.summary),
                      el(
                        'span',
                        cls: 'article-read-link',
                        children: [Component.text('記事を読む'), icon('arrow')],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          el(
            'section',
            cls: 'wrap journal-articles',
            attrs: {'aria-labelledby': 'articles-heading'},
            children: [
              el(
                'div',
                cls: 'articles-heading',
                children: [
                  el('h2', id: 'articles-heading', text: 'すべての記事'),
                  el(
                    'span',
                    cls: 'article-count',
                    text:
                        '${blogPosts.length.toString().padLeft(2, '0')} '
                        '${blogPosts.length == 1 ? 'ARTICLE' : 'ARTICLES'}',
                    attrs: {'data-article-count': '', 'aria-live': 'polite'},
                  ),
                ],
              ),
              el(
                'div',
                cls: 'article-filters',
                attrs: {'role': 'group', 'aria-label': '記事をカテゴリで絞り込む'},
                children: [
                  for (final category in [
                    'すべて',
                    ...blogPosts.map((post) => post.category).toSet(),
                  ])
                    el(
                      'button',
                      cls: 'filter-button',
                      text: category,
                      attrs: {
                        'type': 'button',
                        'data-category-filter': category,
                        'aria-pressed': category == 'すべて' ? 'true' : 'false',
                        'aria-controls': 'article-grid',
                      },
                    ),
                ],
              ),
              el(
                'div',
                cls: 'article-grid',
                id: 'article-grid',
                children: [
                  for (final post in blogPosts)
                    el(
                      'article',
                      cls: 'post-card',
                      attrs: {'data-article-category': post.category},
                      children: [
                        el(
                          'a',
                          cls: 'post-card-link',
                          attrs: {'href': post.url},
                          children: [
                            postCover(post),
                            el(
                              'div',
                              cls: 'post-card-body',
                              children: [
                                postMeta(post),
                                el('h3', text: post.title),
                                el('p', text: post.summary),
                                el(
                                  'span',
                                  cls: 'card-read-link',
                                  children: [
                                    Component.text('記事を読む'),
                                    icon('arrow'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
      blogFooter(),
    ],
  );
}

class ArticleSection {
  const ArticleSection(
    this.id,
    this.title,
    this.paragraphs, {
    this.code,
    this.codeLabel = 'workflow.dart',
    this.codeCaption,
  });
  final String id;
  final String title;
  final List<String> paragraphs;
  final String? code;
  final String codeLabel;
  final String? codeCaption;
}

const articleSections = <String, List<ArticleSection>>{
  'v2-1-0': [
    ArticleSection('release', 'v2.1.0 でできるようになったこと。', [
      '2026年10月2日、GenuineCI v2.1.0 をリリースしました。今回は、Android のビルドをDartから書くためのヘルパーと、CLIで使用するチームを切り替える機能を追加しています。',
      'v2.0.0 から18コミット、65ファイルの変更です。ワークフロー SDK の独立した利用に向けた整備や、静的解析の設定、ワークスペースのパス生成も改善しました。',
    ]),
    ArticleSection(
      'android-builds',
      'APKもAABも、Dartのワークフローから。',
      [
        'FlutterCI に buildApk() と buildAab() を追加しました。APKとAndroid App Bundleのビルドを、解析やテストと同じようにawaitで並べて書けます。',
        'flavorでプロダクトフレーバーを指定でき、dirでその処理の作業ディレクトリを変更できます。どちらも省略できるため、まずは引数なしで使い始められます。',
        'GenuineCI自身のDashboardにも、署名に必要なファイルをシークレットから復元し、APKとAABをビルドするCIワークフローを追加しました。',
      ],
      code: "await ci.flutter.buildApk(flavor: 'staging');\nawait ci.flutter.buildAab(flavor: 'production');",
      codeCaption: 'OpenCI.init()で作成したciを使う処理部分の抜粋です。初期化とimportは省略しています。',
    ),
    ArticleSection(
      'static-analysis',
      '解析の厳しさを、プロジェクトに合わせる。',
      [
        'staticAnalysis() に、fatalInfo・noFatalInfos・noFatalWarningsのオプションを追加しました。infoを失敗として扱うか、infoやwarningでビルドを止めないかを、ワークフローごとに設定できます。',
        'analyticsはデフォルトで抑制します。必要な場合はsuppressAnalytics: falseを指定でき、従来どおりdirで解析対象の作業ディレクトリも変更できます。',
      ],
      code: 'await ci.flutter.staticAnalysis(\n  fatalInfo: true,\n);',
      codeCaption: 'infoを失敗として扱う設定例です。初期化とimportは省略しています。',
    ),
    ArticleSection(
      'switch-team',
      'CLIから、使うチームを切り替える。',
      [
        'openci switch teamで、ログイン中のプロファイルに所属するチームを取得し、上下キーとEnterで選択できるようになりました。現在のチームを表示し、長い一覧や日本語のチーム名にも対応しています。',
        '選択したチームは現在のプロファイルに保存され、その後のシークレット操作にも反映されます。トークンやサーバー設定、他のプロファイルは保持し、キャンセル時は元のチームをそのまま使います。',
        '対話入力の後始末とシグナル処理を共通化し、macOS ARM64で端末終了時にクラッシュする問題への対策も取り込みました。',
      ],
      code: 'openci switch team\nopenci list secrets\nopenci sync secrets',
      codeLabel: 'ターミナル',
      codeCaption: 'openci loginでログインした後に実行してください。',
    ),
    ArticleSection('workflow-sdk', 'SDKとパス生成も、使いやすく。', [
      'openci_workflowは0.1.1になりました。サーバー側のopenci_sharedやChopperへの依存を外し、単体利用とpub.dev公開に向けて、README・使用例・ライセンス・パッケージ情報を整備しています。',
      'openci sync pathsはワークスペースの深い階層まで収集するようになりました。たとえばWorkspacePaths.root.apps.dashboard.android.appのように、Androidの設定ファイルを置く場所にも型のあるパスを使えます。ビルド出力や依存、隠しディレクトリは生成対象から除外します。',
      'あわせてGenuineCIのLPとブログをJasprで追加しました。このブログでも、リリース内容と開発の記録をお届けしていきます。',
    ]),
  ],
};

class BlogArticlePage extends StatelessComponent {
  const BlogArticlePage(this.post, {super.key});
  final BlogPost post;

  @override
  Component build(BuildContext context) {
    final sections = articleSections[post.slug]!;
    final nextPost = blogPosts.length > 1
        ? blogPosts[(blogPosts.indexOf(post) + 1) % blogPosts.length]
        : null;
    return el(
      'div',
      cls: 'journal-page article-page',
      children: [
        socialMetadata(
          title: '${post.title.replaceAll('\n', '')} — GenuineCI Blog',
          description: post.summary,
          path: post.url,
          imagePath: post.imagePath,
          imageAlt: 'GenuineCI ${post.coverTitle} is here. — 黄色いリリースバナー',
          type: 'article',
          section: post.category,
        ),
        link('本文へスキップ', '#main', cls: 'skip-link'),
        blogHeader(),
        el(
          'main',
          id: 'main',
          children: [
            el(
              'article',
              children: [
                el(
                  'div',
                  cls: 'wrap article-masthead',
                  children: [
                    link('← ブログ一覧', '/blog/', cls: 'back-to-blog'),
                    postMeta(post),
                    el('h1', text: post.title),
                    el('p', cls: 'article-lead', text: post.summary),
                    el(
                      'div',
                      cls: 'article-byline',
                      children: [
                        el(
                          'span',
                          cls: 'author-monogram',
                          text: 'g',
                          attrs: {'aria-hidden': 'true'},
                        ),
                        el('span', text: 'GenuineCI Team'),
                      ],
                    ),
                  ],
                ),
                el(
                  'div',
                  cls: 'wrap article-cover-wrap',
                  children: [postCover(post, featured: true)],
                ),
                el(
                  'div',
                  cls: 'wrap article-layout',
                  children: [
                    el(
                      'aside',
                      cls: 'article-sidebar',
                      children: [
                        el(
                          'nav',
                          attrs: {'aria-label': '記事の目次'},
                          children: [
                            el(
                              'p',
                              cls: 'toc-heading',
                              text: 'IN THIS ARTICLE',
                            ),
                            el(
                              'ol',
                              children: [
                                for (final section in sections)
                                  el(
                                    'li',
                                    children: [
                                      link(section.title, '#${section.id}'),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                        el(
                          'p',
                          cls: 'article-aside-note',
                          text: 'Flutter & Dartのために。\nDartでつくられた、\nオープンソースのCI。',
                        ),
                      ],
                    ),
                    el(
                      'div',
                      cls: 'article-body',
                      children: [
                        for (final section in sections)
                          el(
                            'section',
                            id: section.id,
                            children: [
                              el('h2', text: section.title),
                              for (final paragraph in section.paragraphs)
                                el('p', text: paragraph),
                              if (section.code != null) ...[
                                el(
                                  'div',
                                  cls: 'article-code',
                                  children: [
                                    el(
                                      'div',
                                      cls: 'article-code-label',
                                      children: [
                                        icon('terminal'),
                                        el('span', text: section.codeLabel),
                                      ],
                                    ),
                                    el(
                                      'pre',
                                      attrs: {
                                        'tabindex': '0',
                                        'aria-label':
                                            '${section.codeLabel}のコード例',
                                      },
                                      children: [
                                        RawText(
                                          '<code>${highlightedDart(section.code!)}</code>',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (section.codeCaption != null)
                                  el(
                                    'p',
                                    cls: 'code-caption',
                                    text: section.codeCaption,
                                  ),
                              ],
                            ],
                          ),
                        el(
                          'div',
                          cls: 'article-endmark',
                          text: 'g.',
                          attrs: {'aria-hidden': 'true'},
                        ),
                        el(
                          'div',
                          cls: 'article-source-links',
                          children: [
                            link(
                              'GitHubでv2.1.0のリリースノートを見る',
                              'https://github.com/openci-org/openci/releases/tag/v2.1.0',
                              cls: 'text-link',
                              arrow: 'external',
                            ),
                            link(
                              'v2.0.0からの全差分を見る',
                              'https://github.com/openci-org/openci/compare/v2.0.0...v2.1.0',
                              cls: 'text-link',
                              arrow: 'external',
                            ),
                          ],
                        ),
                        link(
                          'GenuineCI を詳しく見る',
                          '/',
                          cls: 'text-link',
                          arrow: 'arrow',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (nextPost != null)
              el(
                'section',
                cls: 'wrap article-next',
                attrs: {'aria-label': '次の記事'},
                children: [
                  el('p', cls: 'eyebrow', text: 'READ NEXT'),
                  el(
                    'a',
                    attrs: {'href': nextPost.url},
                    children: [
                      el('h2', text: nextPost.title.replaceAll('\n', '')),
                      icon('arrow'),
                    ],
                  ),
                  link('すべての記事を見る', '/blog/', cls: 'back-to-blog'),
                ],
              ),
          ],
        ),
        blogFooter(),
      ],
    );
  }
}
