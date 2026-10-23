# GenuineCI website

Jasprで実装したGenuineCIのLP・ブログ・Docsです。ブランドカラーは **#FFFB00** と黒。
英語は `/en/`、日本語は `/ja/` に分けて静的HTMLを生成します。
`/` はFirebase Hostingの301リダイレクトで `/en/` へ転送します。
ブラウザーの言語やIPによる自動切り替えは行いません。
LPのビルド結果はデザイン確認用のサンプルです。
全ページに `noindex, nofollow` を設定しています。
LP・ブログ・Docsに言語別のcanonical、hreflang、OGPとXの `summary_large_image` を設定しています。
公開URLは `https://genuineci.com` です。

## 開発・プレビュー

Flutter **3.44.8** / Dart **3.12.2**、またはFlutter **3.47.x** / Dart **3.13.x** を使用できます。
`build_web_compilers: ^4.8.0` で、使用中のDart SDKとJasprのanalyzer 12依存に対応するバージョンを選択します。
SDKを切り替えると共有lockfileの更新が必要になるため、依存取得では `--enforce-lockfile` を付けません。

リポジトリのrootから実行します。

```sh
flutter pub get
cd apps/website
dart run jaspr_cli:jaspr serve --port 8081
```

`http://localhost:8081/en/` または `/ja/` を開きます。以下は英語版のルートです。
日本語版は `/en/` を `/ja/` に置き換えます。

- `/en/`: LP・Pricing
- `/en/blog/`: ブログ一覧（注目記事・カテゴリ絞り込み）
- `/en/blog/v2-1-0/`、`/en/blog/v2-2-0/`、`/en/blog/v2-3-0/`: リリース記事
- `/en/docs/`: Docsのホーム
- `/en/docs/quickstart/`: クイックスタート
- `/en/docs/workflows/`、`/en/docs/triggers/`、`/en/docs/flutter/`、`/en/docs/secrets/`: ワークフローのガイド
- `/en/docs/cli/`、`/en/docs/self-hosting/`: CLIとセルフホストのガイド

言語切り替えは同じページの対訳へ移動します。クエリと共通のセクションID（`#pricing` など）は維持します。
翻訳で変わるMarkdown見出しのIDは引き継がず、記事の先頭へ移動します。
翻訳がないページでは対訳のリンクを無効にし、存在しないURLをhreflangへ追加しません。

このアプリはrootのPub workspaceに含まれ、rootの `pubspec.lock` を共有します。
rootでの `flutter pub get` でこのアプリの依存関係も取得できます。
Jasprと既存のコード生成ツールはanalyzer 12で依存解決します。
VS Codeの `openci.code-workspace` には登録済みです。

## 記事の編集・追加

ブログは [`jaspr_content`](https://docs.jaspr.site/content/quick_start) で
`content/<en|ja>/blog/` のMarkdownを読み込みます。本文・記事情報・OGPは
`content/ja/blog/v2-1-0.md` のMarkdownとfrontmatterで編集できます。

新しい記事は `content/<en|ja>/blog/<slug>.md` を追加してください。
`layout: blog-article`、`title`、`description`、`category`、`date`（`"YYYY-MM-DD"`）を
frontmatterに指定すると、`/<en|ja>/blog/<slug>/` のページとブログ一覧へ自動的に反映されます。
対訳は同じslugで両言語に追加します。一覧は現在の言語の記事を日付の新しい順で表示します。`author`、`readTime`、`coverLabel`、`coverTitle`、
`image`、`imageAlt` も指定できます。

本文・見出し・リストはJaspr Contentの標準タイポグラフィを使い、目次を見出しから生成します。
Dartのコードフェンスには標準のシンタックスハイライトとコピー操作が付きます。
`bash` などのコードは同じコードブロックで文字列をそのまま表示します。

## Docsの編集・追加

Docsは `content/<en|ja>/docs/` のMarkdownを読み込みます。frontmatterに
`layout: genuine-docs`、`title`、`description`、`group` を指定すると、
`/<en|ja>/docs/<slug>/` にページを生成します。`eyebrow` と `reading` は任意です。
`lib/layouts/docs_layout.dart` の `docsNavigation` に追加すると、サイドバーと
前後のページリンクにも反映されます。ホームの本文は `lib/pages/docs_home.dart` で編集します。

本文の見出しから目次を生成し、現在の言語のDocsのタイトル・説明・Markdown本文をローカル検索できます。
検索はヘッダーのボタン、または Cmd/Ctrl+K で開きます。
コードサンプルにはコピーとLight / Dark切り替えがあり、選択した背景を全ブロックに反映します。
選択はブラウザーに保存され、ページ移動・再読み込み後も維持されます。
狭い画面ではサイドバーをメニューに、目次を折りたたみ表示に切り替えます。

## 検証・静的ビルド

```sh
dart format --output=none --set-exit-if-changed lib test
dart run jaspr_cli:jaspr build --port 62841
dart analyze --fatal-infos
dart test
python3 -m http.server 8081 --bind 127.0.0.1 --directory build/jaspr
```

`build/jaspr/` に各ルートの `index.html` と公開アセットが出力されます。
ビルドで `main.client.options.dart` と `main.server.options.dart` を生成してから静的解析を実行します。
ビルドには専用ポート62841を使います。使用中の場合は `--port` に別の空きポートを指定してください。
CSS・操作用JavaScript・faviconはHTMLにも埋め込み、外部フォントは使いません。
サイト内リンクは `/` から始まるため、上記のHTTPサーバーで確認してください。

`openci/website_ci.dart` はdevelopへのPRとpushで、依存取得・フォーマット・
静的解析・静的サイト生成・生成HTMLのテストを実行します。公開先を切り替える処理は含みません。
CIでは実行ごとに空きポートを選び、プレビューや別のビルドとの固定ポートの競合を避けます。

## Firebase Hosting

`genuineci.com` はFirebaseプロジェクト `openci-b1b91` のHostingサイト
`genuineci-website` に接続されています。`firebase.json` と `.firebaserc` で
`website` ターゲットの公開先を指定し、`build/jaspr/` を配信します。
各言語のLP・ブログ・Docsは、それぞれの生成HTMLを配信します。
旧 `/blog/…` と `/docs/…` は同じslugの `/ja/blog/…` と `/ja/docs/…` へ301で転送し、既存の日本語の見出しIDを維持します。
言語付きのURLを別言語へ自動転送しません。`/` のみ英語版へ転送します。
Jaspr開発サーバーや単純なHTTPサーバーはHostingのリダイレクトを適用しないため、
転送の確認には `firebase emulators:start --only hosting --project openci-b1b91` を使います。
Jasprの `/` は開発・クロール用の英語LPで、canonicalは `/en/` です。

Firebase CLIのGoogleログインと上記のFlutter / Dart環境が必要です。
このディレクトリから実行してください。

```sh
firebase deploy --only hosting:website --project openci-b1b91
```

デプロイ前に依存取得・静的ビルド・生成HTMLのテストを自動実行し、
失敗した場合は公開を中止します。
公開先は `https://genuineci.com/`、Hosting標準URLは
`https://genuineci-website.web.app/` です。

## 構成

- `lib/main.server.dart`: ContentApp・Markdownの読み込み・LPルート・HTMLメタ情報
- `lib/main.client.dart`: Jaspr Contentのクライアント初期化（コードコピー）
- `lib/pages/landing_page.dart`: LP
- `lib/pages/blog_page.dart`: 読み込んだ記事から作るブログ一覧・共通ヘッダーとフッター
- `lib/layouts/blog_layout.dart`: ブログ一覧と記事のPageLayout・目次
- `lib/layouts/docs_layout.dart`, `lib/pages/docs_home.dart`: Docsのナビゲーション・検索データ・ホーム
- `lib/l10n/`: URLからの言語判定、対訳ページの検出、共通UIの翻訳ヘルパー
- `lib/components/language_switcher.dart`: 全ページ共通の言語リンク
- `lib/models/blog_post.dart`: frontmatterから取得する記事情報・表示順
- `content/<en|ja>/blog/`: ブログ一覧の設定とMarkdown記事
- `content/<en|ja>/docs/`: Docsの設定とMarkdownガイド
- `lib/components/`: HTMLヘルパー・LPのDartコード表示・ブログのコード表示
- `lib/components/social_metadata.dart`: canonical・OGP・X Cardの共通メタ情報
- `lib/components/docs_code_block.dart`, `lib/components/code_theme_toggle.dart`: Docsのコード表示・背景切り替え
- `web/site.css`, `web/blog.css`: 共通・各ページのスタイル
- `web/site.js`, `web/blog.js`: ワークフロー例切り替え・カテゴリ絞り込み
- `web/docs.css`, `web/docs.js`: Docsのスタイル・検索・目次・コードコピーと背景切り替え
- `web/favicon.png`: 提供された `Favicon(1).png` を加工せず使用
- `web/ogp/v2-1-0.jpg`: 記事の黄色いバナーを書き出した1200×630の共有用画像。共有用の見出しは左余白を120pxに調整し、OGP・Xの画像URLには `?v=2` を付けています。
- `firebase.json`, `.firebaserc`: `genuineci-website` への公開設定

## 公開前に確認すること

- LPのビルド画面のサンプル値を公開用に整える。
- `noindex, nofollow` を公開方針に合わせて変更する。
- `https://genuineci.com` の記事URLと `/ogp/v2-1-0.jpg` を外部から取得できることを確認する。
- `https://github.com/openci-org/openci` と `https://dashboard.openci.org/` の
  導線を正式なGenuineCIのURLに合わせて確認する。

Dartのコード例は `ci.run()`・`ci.flutter.staticAnalysis()`・
`ci.flutter.unitTests()` の処理部分を示したもので、初期化とimportは省略しています。
