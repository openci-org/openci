---
title: トリガー
description: ブランチ、プルリクエスト、タグ、変更されたファイルを条件に、ワークフローを実行します。
---

## pushで実行する

push の `branch` には、コミットが push されるブランチを指定します。

```dart
ciTriggers: [
  CITrigger.push(branch: 'main'),
],
```

タグの push も対象にできます。たとえば `CITrigger.push(branch: 'refs/tags/v*')` は `v1.2.0` タグの push に一致します。

## GitHub Releaseの公開で実行する

```dart
ciTriggers: [
  CITrigger.release(tag: 'v*'),
],
```

SDK 0.5.0 以降の `release` は、プレリリースを含む Release の公開時に実行されます。`tag` を省略するとすべてのタグが対象になります。ドラフト保存、説明の編集、タグだけの push では起動しません。`tag` には `refs/tags/` を付けず、タグ名または `*` を含むパターンを文字列リテラルで指定します。`paths` は使えません。

ワークフローの読み取りとビルドには、Release のタグが指すコミットを使います。そのコミットにワークフローを含めてください。OpenCI 側の Release イベント対応のデプロイと、GitHub App での **Release** イベントの購読および Contents の読み取り権限が必要です。

## pull requestで実行する

PR のチェックは、作業ブランチとマージ先が同じ連携済みリポジトリにある場合に実行されます。`branch` に指定するのは **マージ先（ベースブランチ）** です。この例では `feature/login` から `main` に向けた PR でチェックが動きます。

```dart
ciTriggers: [
  CITrigger.pullRequest(branch: 'main'),
],
```

## 複数のトリガーを組み合わせる

PR を積み重ねると、2 番目の PR のマージ先は最初の PR の作業ブランチになります。`branch: '*'` を使うと、どのブランチ向けの PR でもチェックが動きます。push は別のトリガーで `main` だけに絞れます。いずれかのトリガーに一致すると実行されます。

```dart
final ci = await OpenCI.init(
  workflowName: 'Flutter CI',
  ciTriggers: [
    CITrigger.push(branch: 'main'),
    CITrigger.pullRequest(branch: '*'),
  ],
);
```

## 特定のファイルが変わったときだけ実行する

絞り込みたい push または PR のトリガーに `paths` を追加します。次の例では、モバイルアプリ、共有パッケージ、各パッケージの `pubspec.yaml`、ロックファイル、ワークフロー自身のいずれかに変更があると PR のチェックが動きます。

```dart
ciTriggers: [
  CITrigger.pullRequest(
    branch: '*',
    paths: [
      'apps/mobile/**',
      'packages/shared/**',
      '**/pubspec.yaml',
      'pubspec.lock',
      'openci/flutter_ci.dart',
    ],
  ),
],
```

リポジトリルートからの相対パスを、1 件以上の文字列リテラルで指定します。大文字と小文字は区別されます。パス内の `*` は 1 階層内、`**` は複数の階層にまたがって一致します。`paths` を省略すると、そのトリガーは変更ファイルにかかわらず実行されます。

PR では PR 全体の差分、push では push 前後のコミット間の差分が対象です。差分をすべて取得できて該当ファイルが 1 件もなければ、GitHub のチェックは **Skipped** になり、ビルドマシンは起動しません。差分をすべて取得できない場合はチェックが動きます。ローカルで Dart ファイルを実行すると、これらの条件にかかわらず処理が実行されます。

## 実行されないとき

- ワークフローの Dart ファイルが、リポジトリの `openci/` 直下にあるか確認する
- イベントと対象ブランチを確認する。OpenCI が実行前に読み取れるよう、ワークフロー名とブランチ名は文字列リテラルで指定する
- GitHub Appが対象リポジトリにアクセスできるか確認する
- ダッシュボードでビルドが作成されているか、実行マシンが利用できるか確認する

ワークフロー本体の書き方は[Dartでワークフローを書く](/ja/docs/workflows/)を参照してください。
