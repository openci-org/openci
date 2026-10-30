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

### GetManagedSecretContext
#### Required Arguments
```dart
String teamId = ...;
String actorUid = ...;
SecretsConnector.instance.getManagedSecretContext(
  teamId: teamId,
  actorUid: actorUid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetManagedSecretContextData, GetManagedSecretContextVariables>`
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

final result = await SecretsConnector.instance.getManagedSecretContext(
  teamId: teamId,
  actorUid: actorUid,
);
GetManagedSecretContextData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String actorUid = ...;

final ref = SecretsConnector.instance.getManagedSecretContext(
  teamId: teamId,
  actorUid: actorUid,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetDueSecretVersions
#### Required Arguments
```dart
// No required arguments
SecretsConnector.instance.getDueSecretVersions().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetDueSecretVersionsData, void>`
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

final result = await SecretsConnector.instance.getDueSecretVersions();
GetDueSecretVersionsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = SecretsConnector.instance.getDueSecretVersions().ref();
ref.execute();

ref.subscribe(...);
```


### GetSecretVersionReferences
#### Required Arguments
```dart
String path = ...;
SecretsConnector.instance.getSecretVersionReferences(
  path: path,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSecretVersionReferencesData, GetSecretVersionReferencesVariables>`
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

final result = await SecretsConnector.instance.getSecretVersionReferences(
  path: path,
);
GetSecretVersionReferencesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String path = ...;

final ref = SecretsConnector.instance.getSecretVersionReferences(
  path: path,
).ref();
ref.execute();

ref.subscribe(...);
```


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

### CommitManagedSecret
#### Required Arguments
```dart
String teamId = ...;
String actorUid = ...;
String name = ...;
String path = ...;
SecretsConnector.instance.commitManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  path: path,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CommitManagedSecret, we created `CommitManagedSecretBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CommitManagedSecretVariablesBuilder {
  ...
   CommitManagedSecretVariablesBuilder expectedPath(String? t) {
   _expectedPath.value = t;
   return this;
  }

  ...
}
SecretsConnector.instance.commitManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  path: path,
)
.expectedPath(expectedPath)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CommitManagedSecretData, CommitManagedSecretVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await SecretsConnector.instance.commitManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  path: path,
);
CommitManagedSecretData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String actorUid = ...;
String name = ...;
String path = ...;

final ref = SecretsConnector.instance.commitManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  path: path,
).ref();
ref.execute();
```


### RenameManagedSecret
#### Required Arguments
```dart
String teamId = ...;
String actorUid = ...;
String name = ...;
String newName = ...;
String expectedPath = ...;
SecretsConnector.instance.renameManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  newName: newName,
  expectedPath: expectedPath,
).execute();
```

#### Optional Arguments
We return a builder for each query. For RenameManagedSecret, we created `RenameManagedSecretBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class RenameManagedSecretVariablesBuilder {
  ...
   RenameManagedSecretVariablesBuilder path(String? t) {
   _path.value = t;
   return this;
  }

  ...
}
SecretsConnector.instance.renameManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  newName: newName,
  expectedPath: expectedPath,
)
.path(path)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<RenameManagedSecretData, RenameManagedSecretVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await SecretsConnector.instance.renameManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  newName: newName,
  expectedPath: expectedPath,
);
RenameManagedSecretData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String actorUid = ...;
String name = ...;
String newName = ...;
String expectedPath = ...;

final ref = SecretsConnector.instance.renameManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  newName: newName,
  expectedPath: expectedPath,
).ref();
ref.execute();
```


### DeleteManagedSecret
#### Required Arguments
```dart
String teamId = ...;
String actorUid = ...;
String name = ...;
String expectedPath = ...;
SecretsConnector.instance.deleteManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  expectedPath: expectedPath,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteManagedSecretData, DeleteManagedSecretVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await SecretsConnector.instance.deleteManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  expectedPath: expectedPath,
);
DeleteManagedSecretData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String actorUid = ...;
String name = ...;
String expectedPath = ...;

final ref = SecretsConnector.instance.deleteManagedSecret(
  teamId: teamId,
  actorUid: actorUid,
  name: name,
  expectedPath: expectedPath,
).ref();
ref.execute();
```


### QueueSecretVersionCleanup
#### Required Arguments
```dart
String path = ...;
SecretsConnector.instance.queueSecretVersionCleanup(
  path: path,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<QueueSecretVersionCleanupData, QueueSecretVersionCleanupVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await SecretsConnector.instance.queueSecretVersionCleanup(
  path: path,
);
QueueSecretVersionCleanupData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String path = ...;

final ref = SecretsConnector.instance.queueSecretVersionCleanup(
  path: path,
).ref();
ref.execute();
```


### CompleteSecretVersionCleanup
#### Required Arguments
```dart
String path = ...;
SecretsConnector.instance.completeSecretVersionCleanup(
  path: path,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CompleteSecretVersionCleanupData, CompleteSecretVersionCleanupVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await SecretsConnector.instance.completeSecretVersionCleanup(
  path: path,
);
CompleteSecretVersionCleanupData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String path = ...;

final ref = SecretsConnector.instance.completeSecretVersionCleanup(
  path: path,
).ref();
ref.execute();
```


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
