# Basic Usage

```dart
LogsConnector.instance.AppendBuildLog(appendBuildLogVariables).execute();
LogsConnector.instance.GetBuildLogs(getBuildLogsVariables).execute();
LogsConnector.instance.GetBuildLogWriteState(getBuildLogWriteStateVariables).execute();
LogsConnector.instance.GetBuildStepWriteState(getBuildStepWriteStateVariables).execute();
LogsConnector.instance.GetBuildLogState(getBuildLogStateVariables).execute();
LogsConnector.instance.GetExpiredBuildLogs().execute();
LogsConnector.instance.DeleteExpiredBuildLogs(deleteExpiredBuildLogsVariables).execute();
LogsConnector.instance.CreateBuildStep(createBuildStepVariables).execute();
LogsConnector.instance.UpdateBuildStep(updateBuildStepVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await LogsConnector.instance.GetBuildLogs({ ... })
.afterSequence(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.
