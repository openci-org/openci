# builds SDK

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
BuildsConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetBuildJobs
#### Required Arguments
```dart
String teamId = ...;
BuildsConnector.instance.getBuildJobs(
  teamId: teamId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For GetBuildJobs, we created `GetBuildJobsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class GetBuildJobsVariablesBuilder {
  ...
   GetBuildJobsVariablesBuilder offset(int t) {
   _offset.value = t;
   return this;
  }
  GetBuildJobsVariablesBuilder limit(int t) {
   _limit.value = t;
   return this;
  }

  ...
}
BuildsConnector.instance.getBuildJobs(
  teamId: teamId,
)
.offset(offset)
.limit(limit)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<GetBuildJobsData, GetBuildJobsVariables>`
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

final result = await BuildsConnector.instance.getBuildJobs(
  teamId: teamId,
);
GetBuildJobsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = BuildsConnector.instance.getBuildJobs(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBuildJob
#### Required Arguments
```dart
String id = ...;
BuildsConnector.instance.getBuildJob(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBuildJobData, GetBuildJobVariables>`
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

final result = await BuildsConnector.instance.getBuildJob(
  id: id,
);
GetBuildJobData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = BuildsConnector.instance.getBuildJob(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```

### FindBuildJobs

Search the selected team's jobs by GitHub pull request number or full commit SHA. Supply both to select a particular revision of a PR. The response includes job IDs, status, and stored run IDs for up to three recent attempts.

```dart
final search = BuildsConnector.instance.findBuildJobs(
  teamId: teamId,
  githubBaseUrl: 'https://github.com',
  owner: owner,
  repo: repo,
);
final result = await search.pullRequestNumber(BigInt.from(42)).limit(20).execute();
final jobs = result.data.jobs;
```

Use `commitSha(sha)` for a commit search. Supply `offset(offset)` to request the next page. The query accepts up to 21 jobs per page.

## Mutations

### RetryBuildJob
#### Required Arguments
```dart
String id = ...;
int expectedRetryCount = ...;
BuildsConnector.instance.retryBuildJob(
  id: id,
  expectedRetryCount: expectedRetryCount,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<RetryBuildJobData, RetryBuildJobVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BuildsConnector.instance.retryBuildJob(
  id: id,
  expectedRetryCount: expectedRetryCount,
).execute();
RetryBuildJobData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
int expectedRetryCount = ...;

final ref = BuildsConnector.instance.retryBuildJob(
  id: id,
  expectedRetryCount: expectedRetryCount,
).ref();
ref.execute();
```
