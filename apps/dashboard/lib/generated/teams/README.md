# teams SDK

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
TeamsConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetMyTeams
#### Required Arguments
```dart
// No required arguments
TeamsConnector.instance.getMyTeams().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyTeamsData, void>`
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

final result = await TeamsConnector.instance.getMyTeams();
GetMyTeamsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = TeamsConnector.instance.getMyTeams().ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateTeam
#### Required Arguments
```dart
String id = ...;
String name = ...;
TeamsConnector.instance.createTeam(
  id: id,
  name: name,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateTeamData, CreateTeamVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await TeamsConnector.instance.createTeam(
  id: id,
  name: name,
);
CreateTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String name = ...;

final ref = TeamsConnector.instance.createTeam(
  id: id,
  name: name,
).ref();
ref.execute();
```


### RenameTeam
#### Required Arguments
```dart
String teamId = ...;
String name = ...;
TeamsConnector.instance.renameTeam(
  teamId: teamId,
  name: name,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<RenameTeamData, RenameTeamVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await TeamsConnector.instance.renameTeam(
  teamId: teamId,
  name: name,
);
RenameTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String name = ...;

final ref = TeamsConnector.instance.renameTeam(
  teamId: teamId,
  name: name,
).ref();
ref.execute();
```
