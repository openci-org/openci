---
trigger: always_on
---

- If you modify firestore operations, be sure to update firestore security rule if necessary.

- If you update `apps/worker_cli_node`, be sure to update `package.json` and `package-lock.json` versions, then run `npm run check`, `npm run build`, and `npm run pack:dry-run`.
- If you update legacy Dart packages such as `openci_vm_cli`, be sure to update changelog and version at `pubspec.yaml` and code if necessary.

- For Firestore timestamp fields (createdAt, updatedAt, completedAt, etc.), always use `DateTime.now().toUtc().toIso8601String()` instead of `FieldValue.serverTimestamp`. The Dashboard's `DateTimeConverter` expects ISO8601 strings, so the type must be consistent.

- 実装完了後、ts関連のファイルの変更がある場合はvp checkでフォーマットを必ず確認してください。

- After completing any implementation, always explicitly inform the user of the next steps they need to take (e.g., whether to deploy firebase functions, deploy firestore security rules, hot restart flutter, or publish/update worker cli). However, the agent is allowed (and encouraged) to directly execute deployments (functions, rules) and flutter reloads/restarts by itself during execution.
  - 実装完了後、ユーザーが次に行うべきアクション（Firebase Functionsのデプロイ、Security Rulesのデプロイ、FlutterのHot Restart、あるいはWorker CLIのPublishなど）を必ず明記して報告してください。ただし、セキュリティルールやFunctionsのデプロイ、およびFlutterのHot Reload/Hot Restartは、エージェント自身で直接実行して反映してしまって構いません。
