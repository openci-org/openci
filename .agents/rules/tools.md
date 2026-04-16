---
trigger: always_on
---

- If you modify firestore operations, be sure to update firestore security rule if necessary.

- If you update openci_worker_cli or openci_vm_cli, be sure to update changelog and version at pubspec.yaml and code if necessary.

- For Firestore timestamp fields (createdAt, updatedAt, completedAt, etc.), always use `DateTime.now().toUtc().toIso8601String()` instead of `FieldValue.serverTimestamp`. The Dashboard's `DateTimeConverter` expects ISO8601 strings, so the type must be consistent.
