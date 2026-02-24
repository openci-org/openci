---
trigger: always_on
---

Use pnpm instead of npm.

- If you modify firestore operations, be sure to update firestore security rule if necessary.

- If you update openci_worker_cli or openci_vm_cli, be sure to update changelog and version at pubspec.yaml and code if necessary.

- OpenCI is OSS. All files are public. So, don't push credentials to the public. https://github.com/open-ci-io/openci
