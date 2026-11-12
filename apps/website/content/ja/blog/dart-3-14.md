---
layout: blog-article
title: |-
  Dart 3.14の新機能
  非公式日本語訳
description: Dart 3.14の公式発表の全文日本語訳です。dart migrateによるSDK移行の自動化、刷新されたDartPad、WebAssemblyの高速化、ネイティブAPIとの直接連携などを、冒頭の要約とともに紹介します。
category: Dart
date: "2026-11-12"
readTime: 12 min read
author: Connie Ooi（原著）／OpenCI（日本語訳）
coverLabel: UNOFFICIAL JAPANESE TRANSLATION
coverImage: /images/landing/guide-start.webp
coverTitle: Dart 3.14
---

Connie Ooi 著「[Announcing Dart 3.14](https://dart.dev/blog/announcing-dart-3-14)」（The Dart Blog、2026年11月11日公開）の**非公式日本語訳**です。原文の本文・図版は [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.ja)、コード例は [BSD 3-Clause](https://opensource.org/licenses/BSD-3-Clause) に基づき掲載しています。

## まずは要点だけ

_この節はOpenCIが作成した要約です。次の「日本語訳」から原文の翻訳が始まります。_

- **SDK更新に伴うパッケージの移行を自動化。** `dart migrate` がコードの事前修正とSDK制約の更新を段階的に進めます。新しい機能や推奨スタイルに合わせる追加修正も、任意で適用できます。
- **DartPadを刷新し、ベータ版を公開。** ブラウザー内で解析・コンパイルを実行します。LSP、`pub.dev` のパッケージ、複数ファイルにも対応します。
- **WebAssemblyの対応環境と性能を改善。** 標準化された例外処理を採用し、ブラウザー以外のWasmランタイムでも動かしやすくなりました。SIMDのベンチマークでは、ネイティブとWebAssemblyで最大4倍の高速化を確認しています。
- **バイト列の範囲比較を効率化。** `dart:typed_data` に追加した `rangeEquals` で、ビューの生成や要素ごとのループを書かずに比較できます。
- **ネイティブ連携と開発プロセスも更新。** FFIgenのObjective-C対応とJNIgenが安定版になりました。大きな設計変更を公開の場で議論するRFCプロセスも導入されます。

Flutter側の変更は、[Flutter 3.50の非公式日本語訳](/ja/blog/flutter-3-50/)でも紹介しています。

## 日本語訳

_SDK移行の自動化、WebAssemblyの高速化、DartPadの刷新で、一連の開発作業を改善_

![Dartロゴ入りのパイをオーブンから取り出すDashと、数字「3.14」のイラスト。](/images/blog/dart-3-14/announcement.webp)

_原文のメインビジュアル。出典：The Dart Blog、CC BY 4.0。_

Dart 3.14をリリースしました。

今回の更新は、ブラウザーでアイデアを試す段階から、クロスプラットフォームのアプリ開発、次のリリースに向けたパッケージの更新まで、一連の開発作業を支えるものです。

刷新されたDartPadでは、アイデアや `pub.dev` のパッケージを手軽に試せます。`dart migrate` でSDKのバージョン更新に伴うコード移行を自動化できるほか、ハードウェアSIMDによるWebAssemblyの高速化、ブラウザー以外でのWasmモジュールの実行にも対応しました。安定版になったFFIgenとJNIgenを使えば、ネイティブプラットフォームのAPIを直接呼び出せます。

[Dartを更新](https://dart.dev/get-dart) するか、[`flutter upgrade`](https://docs.flutter.dev/install/upgrade) を実行して、新機能を試してみてください。UIフレームワーク側の変更については、あわせて公開された [What's new in Flutter 3.50](https://flutter.dev/blog/whats-new-in-flutter-3-50) をご覧ください。

## 開発ツールの更新

### dart migrateによるパッケージ移行の自動化

Dartパッケージを新しいSDKに対応させるときは、SDK制約の更新に加えて、新しいコーディングスタイルに合わせたり、破壊的変更に対応したりする必要があります。どのlintを有効にし、どのコードを書き換えるべきかを、リリースごとに調べるのは手間がかかります。

新しい `dart migrate` は、パッケージのSDK制約を1バージョンずつ更新しながら、必要なコード修正を自動で進めるツールです。各バージョンへの移行で、次の処理を行います。

1. バージョンを上げる前に必要な `dart fix` の修正を適用します。
2. `pubspec.yaml` に記載したSDK制約の下限を更新します。

更新後は、新しい言語機能や推奨スタイルに合わせるための追加修正も、任意で適用できます。

たとえば、SDK制約が `^3.12.0` のパッケージに、次のコードがあるとします。

```dart
class WeakPasswordException implements Exception {}

void checkPassword(final String password, final int minLength) {
  if (password.length < minLength) {
    throw WeakPasswordException();
  }
}
```

ツールはまず、Dart 3.13ではコンパイルエラーになる引数の `final` を取り除き、pubspecのSDK制約を更新します。その後、任意の追加修正を適用すると、本体が空のクラスをセミコロンで終える新しい構文に書き換えられます。

```dart
class WeakPasswordException implements Exception;

void checkPassword(String password, int minLength) {
  if (password.length < minLength) {
    throw WeakPasswordException();
  }
}
```

処理後は、各段階で行った変更と、まだ適用できる任意の追加修正が表示されます。

```plaintext
my_package:
  3.12.0 -> 3.13.0:
    Preparatory changes:
      2 changes made in 1 file.

      my_package/lib/password.dart
        avoid_final_parameters • 2 changes

    SDK constraint:
      Bumped ^3.12.0 -> ^3.13.0

Optional cleanup fixes can modernize your code further:

  my_package: 1 change in 1 file
    empty_container_bodies • 1 change

To preview them, run 'dart pub get' and then 'dart migrate --dry-run --step=cleanup' on the same packages.
```

変更内容を事前に確認するには、`--dry-run` を使います。

```bash
dart migrate --dry-run
```

変更を適用するには、`--apply` を指定します。

```bash
dart migrate --apply
```

大きなコードベースなどで、SDK制約を更新する前後に修正内容を確認したい場合は、`--step` で実行する段階を指定できます。

```bash
# Only run preparatory fixes without bumping the constraint
dart migrate --apply --step=prepare

# After applying the preparatory fixes, bump the constraint and apply cleanup fixes
dart migrate --apply --step=bump,cleanup
```

最初のコマンドは、SDK制約を変えずに事前修正だけを実行します。続くコマンドで、SDK制約の更新と追加修正を適用できます。

通常は、1回の実行でマイナーバージョンを1つ上げます。複数のバージョンをまとめて移行するには、`--target-sdk` を指定してください。

```bash
dart migrate --apply --target-sdk=3.14.0
```

**対象は、SDK制約でDart 3.0以降を要求するパッケージです。**

詳しくは、[dart migrateのドキュメント](https://dart.dev/tools/dart-migrate) をご覧ください。

### Analysis Serverの高速化

SDKの更新を円滑にするだけでなく、ワークスペースが大きくなってもIDEの応答性を保ち、AIコーディングエージェントを使った作業を高速化することも、ツール開発チームが重視している課題です。Dart Analysis Serverには、次の改善が加わりました。

- **ファイル探索の高速化：** 「参照を検索」などの要求を高速化しました。特に、解析コンテキストが多いワークスペースで効果があります。
- **ほかの操作を待たせる処理の改善：** コード整形など、ほかの操作を妨げていた処理の影響を減らしました。
- **サーバー起動の高速化：** 起動時間を短縮しました。パッケージ設定や解析オプションの変更により、解析処理を再起動する場合も対象です。
- **`documentColor`要求の高速化：** ファイル編集中のこの要求を高速化し、それを待っていた多くの解析サーバー要求も、より早く処理できるようにしました。
- **analyzerプラグインの解析範囲を限定：** 解析対象をプラグインのコンテキスト配下に絞り、解析を高速化しました。

### Pubの更新

#### ETagキャッシュによる依存関係解決の高速化

中規模から大規模なプロジェクトで、キャッシュがある場合の `dart pub` の依存関係解決が速くなり、通信量も大きく減りました。`dart pub get`、`upgrade`、`add` で依存関係を解決するとき、`pub` はパッケージごとに `pub.dev` へバージョン一覧を問い合わせます。新しいバージョンや公開取り下げ、セキュリティ情報を確認するためです。これまでは、何も変わっていなくても、数MBのパッケージ情報を再ダウンロードすることがありました。

今回から、`dart pub` はサーバーの `ETag` をバージョン一覧とともにローカルのpubキャッシュに保存し、次回は `If-None-Match` を付けた条件付きリクエストを送ります。一覧に変更がなければ、`pub.dev` は本文のない `304 Not Modified` を返し、`pub` はキャッシュをそのまま再利用します。

依存パッケージが144個あるFlutterプロジェクトでは、約1.5 MBのバージョン一覧を繰り返し取得せずに済むようになりました。特に、通信が遅い環境や遅延が大きい回線で、キャッシュを使った依存関係解決が速くなります。

### 刷新されたDartPadのベータ版

ブラウザーでDartやFlutterを、より手軽に素早く試せる、新しい [DartPad](https://dartpad.dev/) のベータ版を公開しました。

新しいDartPadは `package:dartpad` を基盤としています。Dartのコンパイラー、analyzer、pubクライアントをWebAssemblyにコンパイルし、Web Worker内でローカルに動かします。コードの解析とコンパイルをブラウザー内で実行するため、リモートサーバーの処理を待たずに結果を得られます。Language Server Protocol（LSP）にも全面的に対応しており、IDEと同じようにコード補完、ホバー時のドキュメント表示、定義への移動、クイックフィックスを利用できます。

`pub.dev` からパッケージを読み込めるのも、大きな変更です。事前に選ばれたパッケージの一覧に制限されず、実際のプロジェクトで使うライブラリをその場で試せます。複数のファイルにも対応し、実際のアプリと同じようにウィジェットやデータモデルを分けて整理できます。

この仕組みは、Dartが開発端末、サーバー、ブラウザーのいずれでも使えるフルスタック言語であることを示しています。コンパイラーなどの基本ツール自体がDartで書かれているため、それらをWebAssemblyにコンパイルすることで、一連の開発作業をブラウザー内で完結できるようになりました。

新しいベータ版は、[dartpad.dev](https://dartpad.dev/) で試せます。

## Webプラットフォームの更新

### ブラウザーとWasmランタイムで、標準の例外処理に対応

DartのWebAssemblyアプリが、より多くのブラウザーや、ブラウザー以外のWasm実行環境で、そのまま動くようになりました。ブラウザー向けの `dart2wasm` は、正式に標準化された [`try_table` による例外処理の命令](https://github.com/dart-lang/sdk/issues/54394) を標準で出力します。[Safari 26.5以前のストリーミングコンパイルの問題](https://github.com/dart-lang/sdk/issues/63543) を回避する対応も加わり、Chrome 137以降、Safari 26.2以降、Firefox 147以降でWebAssemblyを利用できます。

ブラウザー以外では、`try_table` の採用により、`dart compile wasm --standalone` で例外処理のためにJavaScriptのラッパーを使う必要がなくなりました。この機能は、コミュニティの [Simon Binder](https://github.com/simolus3) が貢献したものです。JavaScriptの実行環境を用意せずに、[Wasmtime](https://wasmtime.dev/) などのWasmランタイムで直接動く、標準の `.wasm` バイナリーを生成できます。これにより、エッジワーカー、プラグインシステム、サーバー側のWasm環境でもDartを動かしやすくなりました。

WASIやWebAssembly Component Modelを試したい場合は、Simon Binderが開発するコミュニティパッケージ [`wasm_tools`](https://pub.dev/packages/wasm_tools) と、[GitHubリポジトリ](https://github.com/simolus3/wasm.dart) をご覧ください。

詳しくは、[WebAssemblyのドキュメント](https://dart.dev/web/wasm) をご覧ください。

### 128ビットのWebAssembly SIMDに対応

対応する実行環境が増えたことに加え、WebAssemblyの実行性能も大きく改善しました。

コミュニティの [Modestas Valauskas](https://github.com/modulovalue) による60件以上のSDKへの貢献により、`dart2wasm` は、`Int32x4`、`Float32x4`、`Float64x2` と、それらのtyped-dataリストのビューを、[128ビットのWebAssembly SIMD命令（`v128`）](https://github.com/dart-lang/sdk/issues/64170) に直接コンパイルするようになりました。ネイティブプラットフォームでも、`dart:typed_data` の `Int32x4` の操作を拡充・最適化しました。これらの改善により、ネイティブとWebAssemblyのSIMDベンチマークで、最大4倍の高速化を確認しています。

詳しくは、[`dart:typed_data`ライブラリのドキュメント](https://api.dart.dev/dart-typed_data/) をご覧ください。

### 古いWebライブラリの削除に備える

WebAssemblyの普及とDartのWeb対応の改善に伴い、従来のWebライブラリやJavaScript連携ライブラリは非推奨になっています。対象は、`dart:html`、`dart:js`、`dart:js_util`、`package:js` と、関連する `dart:*` のブラウザー向けライブラリです。これらは、今後のリリースでDart SDKから削除される予定です。移行には時間がかかりますが、`package:web` と `dart:js_interop` を使うことで、WebAssemblyへの完全な対応を含め、Web標準に沿った、より堅牢な実装にできます。

早めに移行箇所を確認できるよう、`dart compile js`（`dart2js`）と `ddc` が [`--no-deprecated-js-interop`](https://github.com/dart-lang/sdk/issues/63919) に対応しました。このフラグを指定すると、対象ライブラリの直接のインポートだけでなく、依存先を経由した間接的なインポートもコンパイル時に拒否します。条件付きインポートで使う、それらのライブラリに対応する `dart.library.*` の環境条件も `false` になります。

パッケージやアプリで `dart compile js --no-deprecated-js-interop` を実行し、残っている利用箇所を [`dart:js_interop`](https://dart.dev/interop/js-interop) と [`package:web`](https://dart.dev/interop/js-interop/package-web) に移行してください。[Flutter 3.50](https://flutter.dev/blog/whats-new-in-flutter-3-50) では、`flutter build web --no-deprecated-js-interop` を使えます。

詳しくは、[JS連携のドキュメント](https://dart.dev/interop/js-interop) と [package:webへの移行ガイド](https://dart.dev/interop/js-interop/package-web) をご覧ください。

## エンジンとランタイムの更新

### dart:typed_dataでバイト列の範囲を高速に比較

性能が重要な処理でバイトバッファーの一部を比較する際も、`sublistView` を作り、`package:collection` の `ListEquality` などで要素を1つずつ比較する必要がなくなりました。`dart:typed_data` に、範囲を比較する拡張メソッド `rangeEquals` を追加しました。対象は、整数型のtyped-dataリストすべて（`Uint8List`、`Int8List`、`Uint8ClampedList`、`Uint16List`、`Int16List`、`Uint32List`、`Int32List`、`Uint64List`、`Int64List`）と `ByteData` です。

```dart
import 'dart:typed_data';

void main() {
  final packet = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]);
  final pngMagic = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

  // Compare packet[0..4] against pngMagic[0..4] without allocating views:
  if (packet.rangeEquals(0, 4, pngMagic)) {
    print('PNG header matched');
  }
}
```

この比較処理は、Dart VMでは `memcmp`、`dart2wasm` ではWasm配列からの直接読み出し（`ByteData` では32ビット単位）、JavaScriptではtyped-arrayの効率的なループに変換されます。どのターゲットでも、新たなメモリー確保を伴わずに高速に比較できます。

詳しくは、[`dart:typed_data`ライブラリのドキュメント](https://api.dart.dev/dart-typed_data/) をご覧ください。

## ネイティブAPIとの直接連携

Dartからネイティブプラットフォームのライブラリを直接呼び出す機能も、本番環境で利用できるようになりました。Dart 3.14では、Objective-C向けの [FFIgen](https://pub.dev/packages/ffigen) と、Java／Kotlin向けの [JNIgen](https://pub.dev/packages/jnigen) が安定版になっています。

プラットフォームチャネルの定型的なコードを手作業で書く代わりに、FFIgenとJNIgenで、Dartらしい型安全なバインディングを自動生成できます。これにより、Objective-C、Java、KotlinのAPIをDartから直接呼び出せます。今回の安定版は、DartパッケージやFlutterプラグインを開発する際の手間を減らすため、数年にわたって設計と改善を重ね、寄せられた意見を反映してきた成果です。用途に合った連携方法の選び方については、今後、[Flutterブログ](https://flutter.dev/blog) で詳しく紹介する予定です。

詳しくは、[ネイティブ連携のドキュメント](https://docs.flutter.dev/interop) をご覧ください。

## 今後の言語機能

Dartチームは、`this` の型昇格とstatic extensionsの開発も進めています。詳細は、今後のリリースで紹介する予定です。

詳しくは、[Dart言語機能の開発計画](https://github.com/dart-lang/language/projects/1) をご覧ください。

## コミュニティ

### DartへのRFCプロセスの導入

Dartの各リリースは、コミュニティからの貢献に支えられています。Dart 3.14のスタンドアロンWebAssemblyやハードウェアSIMDの改善も、その一例です。プロジェクトが大きくなる中で、重要な意思決定を追いやすくし、参加しやすくするため、Dartは大きな変更を提案・評価する新しい手順を導入します。チーム全体の合意が必要な変更では、Request for Comments（RFC）の作成が必須になります。

この手順は、Dartチームのメンバーとコミュニティのコントリビューターの双方が利用できます。Dartチームやプロジェクトの責任者から意見や正式な承認を得るための仕組みです。設計の議論や決定内容を1か所にまとめることで、チームが取り組んでいる内容も把握しやすくします。

詳しくは、[Dart RFCリポジトリ](https://dart.googlesource.com/rfc) をご覧ください。

## Dart 3.14を試す

Dart 3.14では、DartPadで `pub.dev` のパッケージを試す作業、高性能なWebAssemblyアプリやネイティブアプリの公開、`dart migrate` によるバージョン更新の自動化など、開発の各段階を改善しています。Dart製のコンパイラー、analyzer、`pub` クライアント自体をWebAssemblyにコンパイルできるようになり、Dartそのものをブラウザー内で動かせるようになりました。

今回の主要な改善には、オープンソースのコントリビューターによる貢献が数多く含まれています。また、新しいRFCプロセスにより、大きな技術的変更がどのように設計・レビューされ、プロジェクト内で共有されるかも、分かりやすくなります。このリリースでコードの提供、issueの報告、フィードバックに協力してくださった皆さんに感謝します。

[`flutter upgrade`](https://docs.flutter.dev/install/upgrade) を実行するか、[最新のDart SDKをダウンロード](https://dart.dev/get-dart) して、新しい [DartPad](https://dartpad.dev/) のベータ版も試してみてください。ご意見は [GitHubのissueトラッカー](https://github.com/dart-lang/sdk/issues) にお寄せください。Dartの開発を支えてくださり、ありがとうございます。

詳しくは、[Dart SDKの変更履歴](https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md#3140) をご覧ください。

---

## 出典とライセンス

本文・図の説明・代替テキストを日本語に翻訳し、読みやすさを考慮して語順や言い回し、見出し、改行を調整しています。製品名、API名、コード例、バージョン番号は原文の表記を保持しています。冒頭の要約と関連記事への案内はOpenCIが追加しました。

- **原文：** [Announcing Dart 3.14](https://dart.dev/blog/announcing-dart-3-14) — [Connie Ooi](https://github.com/conooi)、The Dart Blog、2026年11月11日公開。
- **日本語訳・要約：** OpenCI。2026年11月12日時点の原文をもとに翻訳しました。原文の一人称はDartチームを指します。
- **本文と図版：** 原文の [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.ja) に基づき掲載しています。日本語訳と追加した要約も、同じCC BY 4.0で公開します。図中の英語は原文のままです。再利用時は原著者・原文・ライセンス・翻訳や変更の表示を保持してください。
- **コード例：** 原文の指定に従い、[BSD 3-Clause](https://opensource.org/licenses/BSD-3-Clause) を適用します。[Dartの著作権表示とライセンス全文](/licenses/dart-BSD-3-Clause.txt) も併せて掲載しています。
- **商標：** DartやFlutterなどの名称・商標は各権利者に帰属します。本記事はGoogle／Dartによる公式翻訳・推奨・承認を示すものではありません。
