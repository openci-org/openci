# github SDK

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
GithubConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetExpiredGitHubConnectionCredentials
#### Required Arguments
```dart
// No required arguments
GithubConnector.instance.getExpiredGitHubConnectionCredentials().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetExpiredGitHubConnectionCredentialsData, void>`
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

final result = await GithubConnector.instance.getExpiredGitHubConnectionCredentials();
GetExpiredGitHubConnectionCredentialsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = GithubConnector.instance.getExpiredGitHubConnectionCredentials().ref();
ref.execute();

ref.subscribe(...);
```


### GetGitHubConnections
#### Required Arguments
```dart
String teamId = ...;
GithubConnector.instance.getGitHubConnections(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetGitHubConnectionsData, GetGitHubConnectionsVariables>`
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

final result = await GithubConnector.instance.getGitHubConnections(
  teamId: teamId,
);
GetGitHubConnectionsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = GithubConnector.instance.getGitHubConnections(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetActiveGitHubConnection
#### Required Arguments
```dart
String githubApiBaseUrl = ...;
BigInt githubAppId = ...;
BigInt installationId = ...;
GithubConnector.instance.getActiveGitHubConnection(
  githubApiBaseUrl: githubApiBaseUrl,
  githubAppId: githubAppId,
  installationId: installationId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetActiveGitHubConnectionData, GetActiveGitHubConnectionVariables>`
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

final result = await GithubConnector.instance.getActiveGitHubConnection(
  githubApiBaseUrl: githubApiBaseUrl,
  githubAppId: githubAppId,
  installationId: installationId,
);
GetActiveGitHubConnectionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String githubApiBaseUrl = ...;
BigInt githubAppId = ...;
BigInt installationId = ...;

final ref = GithubConnector.instance.getActiveGitHubConnection(
  githubApiBaseUrl: githubApiBaseUrl,
  githubAppId: githubAppId,
  installationId: installationId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetGitHubConnectionContext
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
GithubConnector.instance.getGitHubConnectionContext(
  teamId: teamId,
  userId: userId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetGitHubConnectionContextData, GetGitHubConnectionContextVariables>`
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

final result = await GithubConnector.instance.getGitHubConnectionContext(
  teamId: teamId,
  userId: userId,
);
GetGitHubConnectionContextData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;

final ref = GithubConnector.instance.getGitHubConnectionContext(
  teamId: teamId,
  userId: userId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetGitHubConnectionSession
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
String referenceHash = ...;
GithubConnector.instance.getGitHubConnectionSession(
  teamId: teamId,
  userId: userId,
  referenceHash: referenceHash,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetGitHubConnectionSessionData, GetGitHubConnectionSessionVariables>`
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

final result = await GithubConnector.instance.getGitHubConnectionSession(
  teamId: teamId,
  userId: userId,
  referenceHash: referenceHash,
);
GetGitHubConnectionSessionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;
String referenceHash = ...;

final ref = GithubConnector.instance.getGitHubConnectionSession(
  teamId: teamId,
  userId: userId,
  referenceHash: referenceHash,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### DeleteExpiredGitHubConnectionRequest
#### Required Arguments
```dart
String id = ...;
GithubConnector.instance.deleteExpiredGitHubConnectionRequest(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteExpiredGitHubConnectionRequestData, DeleteExpiredGitHubConnectionRequestVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await GithubConnector.instance.deleteExpiredGitHubConnectionRequest(
  id: id,
);
DeleteExpiredGitHubConnectionRequestData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = GithubConnector.instance.deleteExpiredGitHubConnectionRequest(
  id: id,
).ref();
ref.execute();
```


### DeleteExpiredGitHubConnectionSession
#### Required Arguments
```dart
String id = ...;
GithubConnector.instance.deleteExpiredGitHubConnectionSession(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteExpiredGitHubConnectionSessionData, DeleteExpiredGitHubConnectionSessionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await GithubConnector.instance.deleteExpiredGitHubConnectionSession(
  id: id,
);
DeleteExpiredGitHubConnectionSessionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = GithubConnector.instance.deleteExpiredGitHubConnectionSession(
  id: id,
).ref();
ref.execute();
```


### ConfirmGitHubConnection
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
String referenceHash = ...;
String githubApiBaseUrl = ...;
BigInt githubAppId = ...;
BigInt installationId = ...;
BigInt accountId = ...;
String accountType = ...;
String accountLogin = ...;
GithubConnector.instance.confirmGitHubConnection(
  teamId: teamId,
  userId: userId,
  referenceHash: referenceHash,
  githubApiBaseUrl: githubApiBaseUrl,
  githubAppId: githubAppId,
  installationId: installationId,
  accountId: accountId,
  accountType: accountType,
  accountLogin: accountLogin,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<ConfirmGitHubConnectionData, ConfirmGitHubConnectionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await GithubConnector.instance.confirmGitHubConnection(
  teamId: teamId,
  userId: userId,
  referenceHash: referenceHash,
  githubApiBaseUrl: githubApiBaseUrl,
  githubAppId: githubAppId,
  installationId: installationId,
  accountId: accountId,
  accountType: accountType,
  accountLogin: accountLogin,
);
ConfirmGitHubConnectionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;
String referenceHash = ...;
String githubApiBaseUrl = ...;
BigInt githubAppId = ...;
BigInt installationId = ...;
BigInt accountId = ...;
String accountType = ...;
String accountLogin = ...;

final ref = GithubConnector.instance.confirmGitHubConnection(
  teamId: teamId,
  userId: userId,
  referenceHash: referenceHash,
  githubApiBaseUrl: githubApiBaseUrl,
  githubAppId: githubAppId,
  installationId: installationId,
  accountId: accountId,
  accountType: accountType,
  accountLogin: accountLogin,
).ref();
ref.execute();
```


### CreateGitHubConnectionRequest
#### Required Arguments
```dart
String id = ...;
String userId = ...;
String teamId = ...;
String stateHash = ...;
String codeVerifierSecretVersionPath = ...;
GithubConnector.instance.createGitHubConnectionRequest(
  id: id,
  userId: userId,
  teamId: teamId,
  stateHash: stateHash,
  codeVerifierSecretVersionPath: codeVerifierSecretVersionPath,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateGitHubConnectionRequestData, CreateGitHubConnectionRequestVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await GithubConnector.instance.createGitHubConnectionRequest(
  id: id,
  userId: userId,
  teamId: teamId,
  stateHash: stateHash,
  codeVerifierSecretVersionPath: codeVerifierSecretVersionPath,
);
CreateGitHubConnectionRequestData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String userId = ...;
String teamId = ...;
String stateHash = ...;
String codeVerifierSecretVersionPath = ...;

final ref = GithubConnector.instance.createGitHubConnectionRequest(
  id: id,
  userId: userId,
  teamId: teamId,
  stateHash: stateHash,
  codeVerifierSecretVersionPath: codeVerifierSecretVersionPath,
).ref();
ref.execute();
```


### ConsumeGitHubConnectionRequest
#### Required Arguments
```dart
String stateHash = ...;
GithubConnector.instance.consumeGitHubConnectionRequest(
  stateHash: stateHash,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<ConsumeGitHubConnectionRequestData, ConsumeGitHubConnectionRequestVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await GithubConnector.instance.consumeGitHubConnectionRequest(
  stateHash: stateHash,
);
ConsumeGitHubConnectionRequestData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String stateHash = ...;

final ref = GithubConnector.instance.consumeGitHubConnectionRequest(
  stateHash: stateHash,
).ref();
ref.execute();
```


### CreateGitHubConnectionSession
#### Required Arguments
```dart
String id = ...;
String userId = ...;
String teamId = ...;
BigInt githubUserId = ...;
String referenceHash = ...;
String accessTokenSecretVersionPath = ...;
GithubConnector.instance.createGitHubConnectionSession(
  id: id,
  userId: userId,
  teamId: teamId,
  githubUserId: githubUserId,
  referenceHash: referenceHash,
  accessTokenSecretVersionPath: accessTokenSecretVersionPath,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateGitHubConnectionSessionData, CreateGitHubConnectionSessionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await GithubConnector.instance.createGitHubConnectionSession(
  id: id,
  userId: userId,
  teamId: teamId,
  githubUserId: githubUserId,
  referenceHash: referenceHash,
  accessTokenSecretVersionPath: accessTokenSecretVersionPath,
);
CreateGitHubConnectionSessionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String userId = ...;
String teamId = ...;
BigInt githubUserId = ...;
String referenceHash = ...;
String accessTokenSecretVersionPath = ...;

final ref = GithubConnector.instance.createGitHubConnectionSession(
  id: id,
  userId: userId,
  teamId: teamId,
  githubUserId: githubUserId,
  referenceHash: referenceHash,
  accessTokenSecretVersionPath: accessTokenSecretVersionPath,
).ref();
ref.execute();
```
