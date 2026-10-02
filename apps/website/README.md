# GenuineCI website

Jasprで実装したGenuineCIのLPとブログです。ブランドカラーは **#FFFB00** と黒。
ブログには2026年10月2日公開のv2.1.0リリース記事を掲載しています。
LPのビルド結果はデザイン確認用のサンプルです。
全ページに `noindex, nofollow` を設定しています。
LP・ブログ一覧・記事にOGPとXの `summary_large_image` を設定しています。
公開URLは `https://genuineci.com` です。

## 開発・プレビュー

Dart **3.13.x** を使用してください（CI: 3.13.1、ローカル検証: 3.13.2）。
`build_web_compilers 4.8.5` はDart 3.13とJasprのanalyzer 12依存に対応するため固定しています。

```sh
cd apps/website
dart pub get --enforce-lockfile
dart run jaspr_cli:jaspr serve --port 8081
```

`http://localhost:8081/` を開きます。利用するルート:

- `/`: LP
- `/blog/`: ブログ一覧（注目記事・カテゴリ絞り込み）
- `/blog/v2-1-0/`: 「GenuineCI v2.1.0 をリリースしました。」

このアプリはrootのPub workspaceに含めず、独自の `pubspec.lock` を使います。
Jasprのビルダーが必要とするanalyzer 12と、rootに固定されたanalyzer 10の
依存解決を分けるためです。rootでの `flutter pub get` とは別に上記の取得が必要です。
VS Codeの `openci.code-workspace` には登録済みです。

## 検証・静的ビルド

```sh
dart format --output=none --set-exit-if-changed lib test
dart analyze --fatal-infos
dart run jaspr_cli:jaspr build --port 62841
dart test
python3 -m http.server 8081 --bind 127.0.0.1 --directory build/jaspr
```

`build/jaspr/` に各ルートの `index.html` と公開アセットが出力されます。
ビルドには専用ポート62841を使います。使用中の場合は `--port` に別の空きポートを指定してください。
CSS・操作用JavaScript・faviconはHTMLにも埋め込み、外部フォントは使いません。
サイト内リンクは `/` から始まるため、上記のHTTPサーバーで確認してください。

`openci/website_ci.dart` はdevelopへのPRとpushで、依存取得・フォーマット・
静的解析・静的サイト生成・生成HTMLのテストを実行します。公開先を切り替える処理は含みません。

## Firebase Hosting

`genuineci.com` はFirebaseプロジェクト `openci-b1b91` のHostingサイト
`genuineci-website` に接続されています。`firebase.json` と `.firebaserc` で
`website` ターゲットの公開先を指定し、`build/jaspr/` を配信します。
ブログ一覧と記事は、それぞれの生成HTMLを配信します。

Firebase CLIのGoogleログインとDart 3.13.xが必要です。
このディレクトリから実行してください。

```sh
firebase deploy --only hosting:website --project openci-b1b91
```

デプロイ前に依存取得・静的ビルド・生成HTMLのテストを自動実行し、
失敗した場合は公開を中止します。
公開先は `https://genuineci.com/`、Hosting標準URLは
`https://genuineci-website.web.app/` です。

## 構成

- `lib/main.server.dart`: ルーティングとHTMLメタ情報
- `lib/pages/landing_page.dart`: LP
- `lib/pages/blog_page.dart`: ブログ一覧・記事本文・記事ページ
- `lib/components/`: HTMLヘルパーとDartコード表示
- `lib/components/social_metadata.dart`: canonical・OGP・X Cardの共通メタ情報
- `web/site.css`, `web/blog.css`: 共通・各ページのスタイル
- `web/site.js`, `web/blog.js`: ワークフロー例切り替え・カテゴリ絞り込み
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
