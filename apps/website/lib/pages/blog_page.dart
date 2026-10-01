import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/server.dart';

import '../components/dart_code.dart';
import '../components/html.dart';

class BlogPost {
  const BlogPost(
    this.slug,
    this.category,
    this.title,
    this.summary,
    this.readTime,
    this.coverLabel,
  );
  final String slug;
  final String category;
  final String title;
  final String summary;
  final String readTime;
  final String coverLabel;
  String get path => '/blog/$slug';
  String get url => '$path/';
}

const blogPosts = [
  BlogPost(
    'why',
    'プロジェクト',
    'Flutter & Dartに、\n本物のCIを。',
    'いつもの言語で書けて、動く仕組みが見えて、自分のマシンでも動かせる。GenuineCIがつくりたい「本物のCI」の話。',
    '3 min read',
    'OUR PHILOSOPHY',
  ),
  BlogPost(
    'workflows',
    '開発ノート',
    'ワークフローも、\nDartで書こう。',
    'アプリも、CIも、同じ言語で。Dartでワークフローを定義するという選択と、その小さなメリット。',
    '4 min read',
    'WORKFLOWS IN DART',
  ),
  BlogPost(
    'self-host',
    'ガイド',
    '自分のMacで、\nCIを動かすという選択。',
    'Apple Siliconのマシンを、チームのビルド環境に。セルフホストで考えておきたいことを整理します。',
    '3 min read',
    'YOUR MACHINE. YOUR CI.',
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
    el('time', text: '2026.10.01', attrs: {'datetime': '2026-10-01'}),
    el('span', text: post.readTime),
  ],
);

Component postCover(BlogPost post, {bool featured = false}) => el(
  'div',
  cls: 'post-cover cover-${post.slug}${featured ? ' cover-featured' : ''}',
  attrs: {'aria-hidden': 'true'},
  children: [
    el(
      'div',
      cls: 'cover-topline',
      children: [
        el('span', text: 'GenuineCI'),
        el('span', text: '0${blogPosts.indexOf(post) + 1}'),
      ],
    ),
    if (post.slug == 'why') ...[
      el(
        'div',
        cls: 'cover-message',
        children: [
          el('span', text: 'genuine'),
          el('span', text: 'by design.'),
        ],
      ),
      el(
        'div',
        cls: 'cover-bottomline',
        children: [
          el('span', text: post.coverLabel),
          icon('external'),
        ],
      ),
    ] else if (post.slug == 'workflows') ...[
      el(
        'div',
        cls: 'cover-code',
        children: [
          el(
            'span',
            cls: 'cover-code-comment',
            text: '// your workflow, in Dart',
          ),
          el('span', text: 'await ci.run('),
          el('span', cls: 'cover-code-yellow', text: "  'flutter test',"),
          el('span', text: ');'),
        ],
      ),
      el(
        'div',
        cls: 'cover-bottomline',
        children: [
          el('span', text: post.coverLabel),
          el('span', text: '.dart'),
        ],
      ),
    ] else ...[
      el(
        'div',
        cls: 'chip-art',
        children: [
          el('span', cls: 'chip-caption', text: 'APPLE SILICON'),
          el('strong', text: 'M1—M4'),
          el('span', cls: 'chip-subtitle', text: 'READY FOR YOUR NEXT BUILD'),
        ],
      ),
      el(
        'div',
        cls: 'cover-bottomline',
        children: [
          el('span', text: post.coverLabel),
          icon('cpu'),
        ],
      ),
    ],
  ],
);

class BlogPage extends StatelessComponent {
  const BlogPage({super.key});

  @override
  Component build(BuildContext context) => el(
    'div',
    cls: 'journal-page',
    children: [
      Document.head(
        meta: {
          'description':
              'GenuineCIの思想、Dartで書くワークフロー、Apple Siliconとセルフホスト。つくる過程を伝えるブログのデザインモックです。',
        },
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
                  el('span', cls: 'sample-badge', text: 'DESIGN SAMPLE'),
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
                  el('span', text: 'まずは、私たちのこと。'),
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
                    text: '03 ARTICLES',
                    attrs: {'data-article-count': '', 'aria-live': 'polite'},
                  ),
                ],
              ),
              el(
                'div',
                cls: 'article-filters',
                attrs: {'role': 'group', 'aria-label': '記事をカテゴリで絞り込む'},
                children: [
                  for (final category in ['すべて', 'プロジェクト', '開発ノート', 'ガイド'])
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
              el(
                'p',
                cls: 'journal-sample-note',
                text: '掲載内容・日付は、ブログのデザイン確認用サンプルです。',
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
  const ArticleSection(this.id, this.title, this.paragraphs, {this.code});
  final String id;
  final String title;
  final List<String> paragraphs;
  final String? code;
}

const articleSections = <String, List<ArticleSection>>{
  'why': [
    ArticleSection('genuine', '「本物」という名前に込めたこと。', [
      'アプリのコードはDartなのに、ビルドのために別の書き方を覚える。失敗したジョブを見つめながら、マシンの中で何が起きているのかを想像する。CIは開発を助けるものなのに、いつの間にかCIそのものに時間を使っている。',
      'GenuineCIは、その距離を少しずつ縮めるためのプロジェクトです。genuineは「本物の」という意味。日々つくっているものと同じ言語で、仕組みに手が届き、自分たちで使い続けられる。そんなCIをつくることを目指しています。',
    ]),
    ArticleSection('dart-first', 'Flutter & Dartに、まっすぐ。', [
      'GenuineCIはFlutter & Dart専用のCIです。GenuineCI自体もDartで書かれていて、ワークフローもDartで定義します。アプリの外側にあるビルドの手順にも、いつもの言語をそのまま持ち込めます。',
      '専用だからこそ、FlutterとDartの開発者が毎日使う流れを中心に考える。テスト、静的解析、ビルド。その積み重ねを、自然に扱えるものにしたいと考えています。',
    ]),
    ArticleSection('your-ci', '動く場所も、コードも、ひらく。', [
      '実行マシンは、いまはApple Siliconのみ。M1からM4までを対象にしています。そしてGenuineCIはオープンソース。コードを読み、仕組みを理解し、自分のマシンにセルフホストすることもできます。',
      'CIを、ただ結果が返ってくる箱で終わらせない。使う人が理解できて、必要なら手を入れられる道具にする。このブログでは、その考え方や開発の過程を少しずつ言葉にしていきます。',
    ]),
  ],
  'workflows': [
    ArticleSection('same-language', 'アプリとCIの間に、同じ言語を。', [
      'Flutterのアプリを書き、Dartでテストを書き、その続きとしてワークフローもDartで書く。GenuineCIでは、ビルドの手順をDartのコードとして定義します。',
      '新しい設定の記法を増やすのではなく、すでに知っている関数、変数、awaitを使う。複数の手順があるときも、上から順番に読める形で書き始められます。',
    ]),
    ArticleSection(
      'workflow-example',
      'たとえば、解析して、テストする。',
      [
        'パッケージを取得したら、静的解析を実行し、ユニットテストに進む。Flutterプロジェクトでおなじみの流れは、次のような処理で表現できます。',
      ],
      code:
          "await ci.run('flutter pub get');\nawait ci.flutter.staticAnalysis();\nawait ci.flutter.unitTests();",
    ),
    ArticleSection('grow-with-code', 'ワークフローも、育てていくコード。', [
      '手順が増えてきたら、Dartの関数に分ける。何度も使う値には名前を付ける。アプリのコードと同じように、読みやすく整理しながら育てられるのが、プログラミング言語で定義する良さです。',
      'GenuineCI自体もDartで書かれたOSSです。ワークフローの裏側が気になったとき、その実装も同じ言語で読むことができます。書くところから、動くところまで。DartでつながるCIを目指しています。',
    ]),
  ],
  'self-host': [
    ArticleSection('your-machine', 'いつものMacを、ビルドの場所に。', [
      '開発に使っているのと同じApple Siliconで、CIも動かしたい。GenuineCIはセルフホストが可能なオープンソースのCIです。自分たちで管理するマシンを、ワークフローの実行環境として使うことができます。',
      '現在対象としているのは、M1からM4までのApple Siliconマシンです。Flutter & Dart専用のCIとして、まずはこの環境に集中しています。',
    ]),
    ArticleSection('before-start', '最初に、実行環境を決めておく。', [
      'セルフホストを考えるときは、マシンを用意することに加えて、いつ稼働させるか、誰が管理するかを決めておくと見通しが良くなります。開発用のMacを使うのか、ビルド専用に一台を用意するのか。チームの使い方に合わせて考えられます。',
      'FlutterやDart、Xcodeなど、ビルドに必要なツールのバージョンを揃えることも大切です。ワークフローと実行環境をセットで記録しておくと、結果の違いを調べる手掛かりになります。',
    ]),
    ArticleSection('ownership', '自分で管理できるということ。', [
      'マシンの稼働状況、ログ、署名に使う情報。自分で環境を持つ場合は、これらを誰が管理し、どこまでアクセスできるかもチームで決めておきます。運用に必要なことが見える状態をつくるのも、セルフホストの一部です。',
      'GenuineCIのワークフローはDartで定義します。コードとして変更を記録しながら、自分たちのビルド環境を育てていく。CIの動く場所を自分たちで選べることを、大切にしています。',
    ]),
  ],
};

class BlogArticlePage extends StatelessComponent {
  const BlogArticlePage(this.post, {super.key});
  final BlogPost post;

  @override
  Component build(BuildContext context) {
    final sections = articleSections[post.slug]!;
    final nextPost =
        blogPosts[(blogPosts.indexOf(post) + 1) % blogPosts.length];
    return el(
      'div',
      cls: 'journal-page article-page',
      children: [
        Document.head(meta: {'description': post.summary}),
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
                        el('span', cls: 'sample-badge', text: 'サンプル記事'),
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
                                        el('span', text: 'workflow.dart'),
                                      ],
                                    ),
                                    el(
                                      'pre',
                                      attrs: {
                                        'tabindex': '0',
                                        'aria-label': 'Dartワークフローのコード例',
                                      },
                                      children: [
                                        RawText(
                                          '<code>${highlightedDart(section.code!)}</code>',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                el(
                                  'p',
                                  cls: 'code-caption',
                                  text: '処理部分の抜粋です。初期化・importは省略しています。',
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
                          'p',
                          cls: 'article-disclaimer',
                          text: 'この記事はデザイン確認用のサンプルです。正式な製品ドキュメントではありません。',
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
