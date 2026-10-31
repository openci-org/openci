# logs SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
LogsConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetBuildLogs
#### Required Arguments
```dart
String teamId = ...;
String runId = ...;
LogsConnector.instance.getBuildLogs(
  teamId: teamId,
  runId: runId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For GetBuildLogs, we created `GetBuildLogsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class GetBuildLogsVariablesBuilder {
  ...
   GetBuildLogsVariablesBuilder afterSequence(BigInt t) {
   _afterSequence.value = t;
   return this;
  }
  GetBuildLogsVariablesBuilder limit(int t) {
   _limit.value = t;
   return this;
  }

  ...
}
LogsConnector.instance.getBuildLogs(
  teamId: teamId,
  runId: runId,
)
.afterSequence(afterSequence)
.limit(limit)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<GetBuildLogsData, GetBuildLogsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await LogsConnector.instance.getBuildLogs(
  teamId: teamId,
  runId: runId,
);
GetBuildLogsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String runId = ...;

final ref = LogsConnector.instance.getBuildLogs(
  teamId: teamId,
  runId: runId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBuildLogWriteState
#### Required Arguments
```dart
String teamId = ...;
String runId = ...;
String logIds = ...;
LogsConnector.instance.getBuildLogWriteState(
  teamId: teamId,
  runId: runId,
  logIds: logIds,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBuildLogWriteStateData, GetBuildLogWriteStateVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await LogsConnector.instance.getBuildLogWriteState(
  teamId: teamId,
  runId: runId,
  logIds: logIds,
);
GetBuildLogWriteStateData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String runId = ...;
String logIds = ...;

final ref = LogsConnector.instance.getBuildLogWriteState(
  teamId: teamId,
  runId: runId,
  logIds: logIds,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBuildStepWriteState
#### Required Arguments
```dart
String teamId = ...;
String runId = ...;
String stepId = ...;
LogsConnector.instance.getBuildStepWriteState(
  teamId: teamId,
  runId: runId,
  stepId: stepId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBuildStepWriteStateData, GetBuildStepWriteStateVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await LogsConnector.instance.getBuildStepWriteState(
  teamId: teamId,
  runId: runId,
  stepId: stepId,
);
GetBuildStepWriteStateData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String runId = ...;
String stepId = ...;

final ref = LogsConnector.instance.getBuildStepWriteState(
  teamId: teamId,
  runId: runId,
  stepId: stepId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBuildLogState
#### Required Arguments
```dart
String teamId = ...;
String jobId = ...;
String runId = ...;
LogsConnector.instance.getBuildLogState(
  teamId: teamId,
  jobId: jobId,
  runId: runId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBuildLogStateData, GetBuildLogStateVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await LogsConnector.instance.getBuildLogState(
  teamId: teamId,
  jobId: jobId,
  runId: runId,
);
GetBuildLogStateData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String jobId = ...;
String runId = ...;

final ref = LogsConnector.instance.getBuildLogState(
  teamId: teamId,
  jobId: jobId,
  runId: runId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetExpiredBuildLogs
#### Required Arguments
```dart
// No required arguments
LogsConnector.instance.getExpiredBuildLogs().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetExpiredBuildLogsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await LogsConnector.instance.getExpiredBuildLogs();
GetExpiredBuildLogsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = LogsConnector.instance.getExpiredBuildLogs().ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### AppendBuildLog
#### Required Arguments
```dart
String teamId = ...;
String runId = ...;
BigInt expectedLastSequence = ...;
BigInt sequence = ...;
String logId = ...;
String source = ...;
String stream = ...;
String message = ...;
Timestamp occurredAt = ...;
LogsConnector.instance.appendBuildLog(
  teamId: teamId,
  runId: runId,
  expectedLastSequence: expectedLastSequence,
  sequence: sequence,
  logId: logId,
  source: source,
  stream: stream,
  message: message,
  occurredAt: occurredAt,
).execute();
```

#### Optional Arguments
We return a builder for each query. For AppendBuildLog, we created `AppendBuildLogBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class AppendBuildLogVariablesBuilder {
  ...
   AppendBuildLogVariablesBuilder stepId(String? t) {
   _stepId.value = t;
   return this;
  }

  ...
}
LogsConnector.instance.appendBuildLog(
  teamId: teamId,
  runId: runId,
  expectedLastSequence: expectedLastSequence,
  sequence: sequence,
  logId: logId,
  source: source,
  stream: stream,
  message: message,
  occurredAt: occurredAt,
)
.stepId(stepId)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<AppendBuildLogData, AppendBuildLogVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await LogsConnector.instance.appendBuildLog(
  teamId: teamId,
  runId: runId,
  expectedLastSequence: expectedLastSequence,
  sequence: sequence,
  logId: logId,
  source: source,
  stream: stream,
  message: message,
  occurredAt: occurredAt,
);
AppendBuildLogData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String runId = ...;
BigInt expectedLastSequence = ...;
BigInt sequence = ...;
String logId = ...;
String source = ...;
String stream = ...;
String message = ...;
Timestamp occurredAt = ...;

final ref = LogsConnector.instance.appendBuildLog(
  teamId: teamId,
  runId: runId,
  expectedLastSequence: expectedLastSequence,
  sequence: sequence,
  logId: logId,
  source: source,
  stream: stream,
  message: message,
  occurredAt: occurredAt,
).ref();
ref.execute();
```


### DeleteExpiredBuildLogs
#### Required Arguments
```dart
String runId = ...;
BigInt throughSequence = ...;
LogsConnector.instance.deleteExpiredBuildLogs(
  runId: runId,
  throughSequence: throughSequence,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteExpiredBuildLogsData, DeleteExpiredBuildLogsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await LogsConnector.instance.deleteExpiredBuildLogs(
  runId: runId,
  throughSequence: throughSequence,
);
DeleteExpiredBuildLogsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String runId = ...;
BigInt throughSequence = ...;

final ref = LogsConnector.instance.deleteExpiredBuildLogs(
  runId: runId,
  throughSequence: throughSequence,
).ref();
ref.execute();
```


### CreateBuildStep
#### Required Arguments
```dart
String teamId = ...;
String runId = ...;
String stepId = ...;
String name = ...;
int stepOrder = ...;
LogsConnector.instance.createBuildStep(
  teamId: teamId,
  runId: runId,
  stepId: stepId,
  name: name,
  stepOrder: stepOrder,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateBuildStepData, CreateBuildStepVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await LogsConnector.instance.createBuildStep(
  teamId: teamId,
  runId: runId,
  stepId: stepId,
  name: name,
  stepOrder: stepOrder,
);
CreateBuildStepData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String runId = ...;
String stepId = ...;
String name = ...;
int stepOrder = ...;

final ref = LogsConnector.instance.createBuildStep(
  teamId: teamId,
  runId: runId,
  stepId: stepId,
  name: name,
  stepOrder: stepOrder,
).ref();
ref.execute();
```


### UpdateBuildStep
#### Required Arguments
```dart
String teamId = ...;
String runId = ...;
String stepId = ...;
String status = ...;
BigInt durationMs = ...;
LogsConnector.instance.updateBuildStep(
  teamId: teamId,
  runId: runId,
  stepId: stepId,
  status: status,
  durationMs: durationMs,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateBuildStepData, UpdateBuildStepVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await LogsConnector.instance.updateBuildStep(
  teamId: teamId,
  runId: runId,
  stepId: stepId,
  status: status,
  durationMs: durationMs,
);
UpdateBuildStepData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String runId = ...;
String stepId = ...;
String status = ...;
BigInt durationMs = ...;

final ref = LogsConnector.instance.updateBuildStep(
  teamId: teamId,
  runId: runId,
  stepId: stepId,
  status: status,
  durationMs: durationMs,
).ref();
ref.execute();
```
