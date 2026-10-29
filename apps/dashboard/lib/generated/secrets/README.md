# secrets SDK

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
SecretsConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetSecrets
#### Required Arguments
```dart
String teamId = ...;
SecretsConnector.instance.getSecrets(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSecretsData, GetSecretsVariables>`
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

final result = await SecretsConnector.instance.getSecrets(
  teamId: teamId,
);
GetSecretsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = SecretsConnector.instance.getSecrets(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetSecretReference
#### Required Arguments
```dart
String teamId = ...;
String name = ...;
SecretsConnector.instance.getSecretReference(
  teamId: teamId,
  name: name,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSecretReferenceData, GetSecretReferenceVariables>`
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

final result = await SecretsConnector.instance.getSecretReference(
  teamId: teamId,
  name: name,
);
GetSecretReferenceData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String name = ...;

final ref = SecretsConnector.instance.getSecretReference(
  teamId: teamId,
  name: name,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateSecretReference
#### Required Arguments
```dart
String teamId = ...;
String name = ...;
String secretVersionPath = ...;
SecretsConnector.instance.createSecretReference(
  teamId: teamId,
  name: name,
  secretVersionPath: secretVersionPath,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateSecretReferenceData, CreateSecretReferenceVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await SecretsConnector.instance.createSecretReference(
  teamId: teamId,
  name: name,
  secretVersionPath: secretVersionPath,
);
CreateSecretReferenceData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String name = ...;
String secretVersionPath = ...;

final ref = SecretsConnector.instance.createSecretReference(
  teamId: teamId,
  name: name,
  secretVersionPath: secretVersionPath,
).ref();
ref.execute();
```


### UpdateSecretReference
#### Required Arguments
```dart
String teamId = ...;
String name = ...;
String expectedSecretVersionPath = ...;
String secretVersionPath = ...;
SecretsConnector.instance.updateSecretReference(
  teamId: teamId,
  name: name,
  expectedSecretVersionPath: expectedSecretVersionPath,
  secretVersionPath: secretVersionPath,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateSecretReferenceData, UpdateSecretReferenceVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await SecretsConnector.instance.updateSecretReference(
  teamId: teamId,
  name: name,
  expectedSecretVersionPath: expectedSecretVersionPath,
  secretVersionPath: secretVersionPath,
);
UpdateSecretReferenceData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String name = ...;
String expectedSecretVersionPath = ...;
String secretVersionPath = ...;

final ref = SecretsConnector.instance.updateSecretReference(
  teamId: teamId,
  name: name,
  expectedSecretVersionPath: expectedSecretVersionPath,
  secretVersionPath: secretVersionPath,
).ref();
ref.execute();
```


### DeleteSecretReference
#### Required Arguments
```dart
String teamId = ...;
String name = ...;
String expectedSecretVersionPath = ...;
SecretsConnector.instance.deleteSecretReference(
  teamId: teamId,
  name: name,
  expectedSecretVersionPath: expectedSecretVersionPath,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteSecretReferenceData, DeleteSecretReferenceVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await SecretsConnector.instance.deleteSecretReference(
  teamId: teamId,
  name: name,
  expectedSecretVersionPath: expectedSecretVersionPath,
);
DeleteSecretReferenceData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String name = ...;
String expectedSecretVersionPath = ...;

final ref = SecretsConnector.instance.deleteSecretReference(
  teamId: teamId,
  name: name,
  expectedSecretVersionPath: expectedSecretVersionPath,
).ref();
ref.execute();
```
