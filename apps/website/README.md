# GenuineCI website

Jasprで実装したGenuineCIのLPとブログです。ブランドカラーは **#FFFB00** と黒。
ブログ本文・日付・読了時間、LPのビルド結果はデザイン確認用のサンプルです。
全ページに `noindex, nofollow` を設定しています。

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
- `/blog/why/`: 「Flutter & Dartに、本物のCIを。」
- `/blog/workflows/`: 「ワークフローも、Dartで書こう。」
- `/blog/self-host/`: 「自分のMacで、CIを動かすという選択。」

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

## 構成

- `lib/main.server.dart`: ルーティングとHTMLメタ情報
- `lib/pages/landing_page.dart`: LP
- `lib/pages/blog_page.dart`: ブログ一覧・記事本文・記事ページ
- `lib/components/`: HTMLヘルパーとDartコード表示
- `web/site.css`, `web/blog.css`: 共通・各ページのスタイル
- `web/site.js`, `web/blog.js`: ワークフロー例切り替え・カテゴリ絞り込み
- `web/favicon.png`: 提供された `Favicon(1).png` を加工せず使用

## 公開前に確認すること

- サンプル記事、日付、読了時間とビルド画面のサンプル値を公開用に整える。
- `noindex, nofollow` を公開方針に合わせて変更する。
- `https://github.com/openci-org/openci` と `https://dashboard.openci.org/` の
  導線を正式なGenuineCIのURLに合わせて確認する。

Dartのコード例は `ci.run()`・`ci.flutter.staticAnalysis()`・
`ci.flutter.unitTests()` の処理部分を示したもので、初期化とimportは省略しています。
