---
trigger: always_on
---

- Dartファイル更新後は、かならずdart formatおよびflutter analyze or dart analyzeを走らせてください。

- コードのコメントアウトは不要

- コード生成は、dart run build_runner build でok。-dやflutter pub runを使う必要なし。

- openci_worker_cliなど、pub.devに公開しているパッケージのコードを更新した際は、pubspec.yamlのversionをあげて、差分をCHANGELOGにかいて。
