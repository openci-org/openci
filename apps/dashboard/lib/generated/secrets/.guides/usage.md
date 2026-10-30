# Basic Usage

```dart
SecretsConnector.instance.GetManagedSecretContext(getManagedSecretContextVariables).execute();
SecretsConnector.instance.CommitManagedSecret(commitManagedSecretVariables).execute();
SecretsConnector.instance.RenameManagedSecret(renameManagedSecretVariables).execute();
SecretsConnector.instance.DeleteManagedSecret(deleteManagedSecretVariables).execute();
SecretsConnector.instance.QueueSecretVersionCleanup(queueSecretVersionCleanupVariables).execute();
SecretsConnector.instance.GetDueSecretVersions().execute();
SecretsConnector.instance.GetSecretVersionReferences(getSecretVersionReferencesVariables).execute();
SecretsConnector.instance.CompleteSecretVersionCleanup(completeSecretVersionCleanupVariables).execute();
SecretsConnector.instance.CreateSecretReference(createSecretReferenceVariables).execute();
SecretsConnector.instance.UpdateSecretReference(updateSecretReferenceVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await SecretsConnector.instance.RenameManagedSecret({ ... })
.path(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.
