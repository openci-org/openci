# openci_dataconnect SDK

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
DefaultConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetInvitationByToken
#### Required Arguments
```dart
String token = ...;
DefaultConnector.instance.getInvitationByToken(
  token: token,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetInvitationByTokenData, GetInvitationByTokenVariables>`
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

final result = await DefaultConnector.instance.getInvitationByToken(
  token: token,
);
GetInvitationByTokenData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String token = ...;

final ref = DefaultConnector.instance.getInvitationByToken(
  token: token,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListMyPendingInvitations
#### Required Arguments
```dart
// No required arguments
DefaultConnector.instance.listMyPendingInvitations().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListMyPendingInvitationsData, void>`
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

final result = await DefaultConnector.instance.listMyPendingInvitations();
ListMyPendingInvitationsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DefaultConnector.instance.listMyPendingInvitations().ref();
ref.execute();

ref.subscribe(...);
```


### GetCurrentUser
#### Required Arguments
```dart
// No required arguments
DefaultConnector.instance.getCurrentUser().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetCurrentUserData, void>`
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

final result = await DefaultConnector.instance.getCurrentUser();
GetCurrentUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DefaultConnector.instance.getCurrentUser().ref();
ref.execute();

ref.subscribe(...);
```


### ListMyTeams
#### Required Arguments
```dart
// No required arguments
DefaultConnector.instance.listMyTeams().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListMyTeamsData, void>`
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

final result = await DefaultConnector.instance.listMyTeams();
ListMyTeamsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DefaultConnector.instance.listMyTeams().ref();
ref.execute();

ref.subscribe(...);
```


### ListTeamPendingInvitations
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.listTeamPendingInvitations(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListTeamPendingInvitationsData, ListTeamPendingInvitationsVariables>`
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

final result = await DefaultConnector.instance.listTeamPendingInvitations(
  teamId: teamId,
);
ListTeamPendingInvitationsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.listTeamPendingInvitations(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### FindExistingPendingInvitation
#### Required Arguments
```dart
String email = ...;
String teamId = ...;
DefaultConnector.instance.findExistingPendingInvitation(
  email: email,
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<FindExistingPendingInvitationData, FindExistingPendingInvitationVariables>`
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

final result = await DefaultConnector.instance.findExistingPendingInvitation(
  email: email,
  teamId: teamId,
);
FindExistingPendingInvitationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String email = ...;
String teamId = ...;

final ref = DefaultConnector.instance.findExistingPendingInvitation(
  email: email,
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetTeamForMember
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.getTeamForMember(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetTeamForMemberData, GetTeamForMemberVariables>`
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

final result = await DefaultConnector.instance.getTeamForMember(
  teamId: teamId,
);
GetTeamForMemberData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.getTeamForMember(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListTeamMembers
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.listTeamMembers(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListTeamMembersData, ListTeamMembersVariables>`
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

final result = await DefaultConnector.instance.listTeamMembers(
  teamId: teamId,
);
ListTeamMembersData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.listTeamMembers(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListTeamNotificationUsers
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.listTeamNotificationUsers(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListTeamNotificationUsersData, ListTeamNotificationUsersVariables>`
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

final result = await DefaultConnector.instance.listTeamNotificationUsers(
  teamId: teamId,
);
ListTeamNotificationUsersData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.listTeamNotificationUsers(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetTeamById
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.getTeamById(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetTeamByIdData, GetTeamByIdVariables>`
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

final result = await DefaultConnector.instance.getTeamById(
  teamId: teamId,
);
GetTeamByIdData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.getTeamById(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### FindTeamByInstallation
#### Required Arguments
```dart
int installationId = ...;
DefaultConnector.instance.findTeamByInstallation(
  installationId: installationId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<FindTeamByInstallationData, FindTeamByInstallationVariables>`
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

final result = await DefaultConnector.instance.findTeamByInstallation(
  installationId: installationId,
);
FindTeamByInstallationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
int installationId = ...;

final ref = DefaultConnector.instance.findTeamByInstallation(
  installationId: installationId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetSecretsByNames
#### Required Arguments
```dart
String teamId = ...;
String names = ...;
DefaultConnector.instance.getSecretsByNames(
  teamId: teamId,
  names: names,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSecretsByNamesData, GetSecretsByNamesVariables>`
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

final result = await DefaultConnector.instance.getSecretsByNames(
  teamId: teamId,
  names: names,
);
GetSecretsByNamesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String names = ...;

final ref = DefaultConnector.instance.getSecretsByNames(
  teamId: teamId,
  names: names,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetSecretsByNamesForTeam
#### Required Arguments
```dart
String teamId = ...;
String names = ...;
DefaultConnector.instance.getSecretsByNamesForTeam(
  teamId: teamId,
  names: names,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSecretsByNamesForTeamData, GetSecretsByNamesForTeamVariables>`
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

final result = await DefaultConnector.instance.getSecretsByNamesForTeam(
  teamId: teamId,
  names: names,
);
GetSecretsByNamesForTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String names = ...;

final ref = DefaultConnector.instance.getSecretsByNamesForTeam(
  teamId: teamId,
  names: names,
).ref();
ref.execute();

ref.subscribe(...);
```


### FindSecretByName
#### Required Arguments
```dart
String teamId = ...;
String name = ...;
DefaultConnector.instance.findSecretByName(
  teamId: teamId,
  name: name,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<FindSecretByNameData, FindSecretByNameVariables>`
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

final result = await DefaultConnector.instance.findSecretByName(
  teamId: teamId,
  name: name,
);
FindSecretByNameData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String name = ...;

final ref = DefaultConnector.instance.findSecretByName(
  teamId: teamId,
  name: name,
).ref();
ref.execute();

ref.subscribe(...);
```


### FindSecretByNameForTeam
#### Required Arguments
```dart
String teamId = ...;
String name = ...;
DefaultConnector.instance.findSecretByNameForTeam(
  teamId: teamId,
  name: name,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<FindSecretByNameForTeamData, FindSecretByNameForTeamVariables>`
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

final result = await DefaultConnector.instance.findSecretByNameForTeam(
  teamId: teamId,
  name: name,
);
FindSecretByNameForTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String name = ...;

final ref = DefaultConnector.instance.findSecretByNameForTeam(
  teamId: teamId,
  name: name,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetSecretForTeam
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
DefaultConnector.instance.getSecretForTeam(
  id: id,
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSecretForTeamData, GetSecretForTeamVariables>`
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

final result = await DefaultConnector.instance.getSecretForTeam(
  id: id,
  teamId: teamId,
);
GetSecretForTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;

final ref = DefaultConnector.instance.getSecretForTeam(
  id: id,
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetSecretPathForTeam
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
DefaultConnector.instance.getSecretPathForTeam(
  id: id,
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSecretPathForTeamData, GetSecretPathForTeamVariables>`
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

final result = await DefaultConnector.instance.getSecretPathForTeam(
  id: id,
  teamId: teamId,
);
GetSecretPathForTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;

final ref = DefaultConnector.instance.getSecretPathForTeam(
  id: id,
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListSecretsForTeam
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.listSecretsForTeam(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListSecretsForTeamData, ListSecretsForTeamVariables>`
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

final result = await DefaultConnector.instance.listSecretsForTeam(
  teamId: teamId,
);
ListSecretsForTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.listSecretsForTeam(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListEnvironmentVariablesForTeam
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.listEnvironmentVariablesForTeam(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListEnvironmentVariablesForTeamData, ListEnvironmentVariablesForTeamVariables>`
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

final result = await DefaultConnector.instance.listEnvironmentVariablesForTeam(
  teamId: teamId,
);
ListEnvironmentVariablesForTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.listEnvironmentVariablesForTeam(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListWorkerEnvironmentVariables
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.listWorkerEnvironmentVariables(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListWorkerEnvironmentVariablesData, ListWorkerEnvironmentVariablesVariables>`
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

final result = await DefaultConnector.instance.listWorkerEnvironmentVariables(
  teamId: teamId,
);
ListWorkerEnvironmentVariablesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.listWorkerEnvironmentVariables(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListWorkerSecrets
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.listWorkerSecrets(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListWorkerSecretsData, ListWorkerSecretsVariables>`
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

final result = await DefaultConnector.instance.listWorkerSecrets(
  teamId: teamId,
);
ListWorkerSecretsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.listWorkerSecrets(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListWorkflowsForTeam
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.listWorkflowsForTeam(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListWorkflowsForTeamData, ListWorkflowsForTeamVariables>`
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

final result = await DefaultConnector.instance.listWorkflowsForTeam(
  teamId: teamId,
);
ListWorkflowsForTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.listWorkflowsForTeam(
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetWorkflow
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
DefaultConnector.instance.getWorkflow(
  id: id,
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetWorkflowData, GetWorkflowVariables>`
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

final result = await DefaultConnector.instance.getWorkflow(
  id: id,
  teamId: teamId,
);
GetWorkflowData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;

final ref = DefaultConnector.instance.getWorkflow(
  id: id,
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetWorkflowFile
#### Required Arguments
```dart
String id = ...;
DefaultConnector.instance.getWorkflowFile(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetWorkflowFileData, GetWorkflowFileVariables>`
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

final result = await DefaultConnector.instance.getWorkflowFile(
  id: id,
);
GetWorkflowFileData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = DefaultConnector.instance.getWorkflowFile(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListWorkflowFilesForBranch
#### Required Arguments
```dart
String teamId = ...;
String repository = ...;
String branch = ...;
DefaultConnector.instance.listWorkflowFilesForBranch(
  teamId: teamId,
  repository: repository,
  branch: branch,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListWorkflowFilesForBranchData, ListWorkflowFilesForBranchVariables>`
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

final result = await DefaultConnector.instance.listWorkflowFilesForBranch(
  teamId: teamId,
  repository: repository,
  branch: branch,
);
ListWorkflowFilesForBranchData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String repository = ...;
String branch = ...;

final ref = DefaultConnector.instance.listWorkflowFilesForBranch(
  teamId: teamId,
  repository: repository,
  branch: branch,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBuildJob
#### Required Arguments
```dart
String id = ...;
DefaultConnector.instance.getBuildJob(
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

final result = await DefaultConnector.instance.getBuildJob(
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

final ref = DefaultConnector.instance.getBuildJob(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBuildJobForTeam
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
DefaultConnector.instance.getBuildJobForTeam(
  id: id,
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBuildJobForTeamData, GetBuildJobForTeamVariables>`
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

final result = await DefaultConnector.instance.getBuildJobForTeam(
  id: id,
  teamId: teamId,
);
GetBuildJobForTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;

final ref = DefaultConnector.instance.getBuildJobForTeam(
  id: id,
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListBuildJobsForTeam
#### Required Arguments
```dart
String teamId = ...;
int limit = ...;
DefaultConnector.instance.listBuildJobsForTeam(
  teamId: teamId,
  limit: limit,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListBuildJobsForTeamData, ListBuildJobsForTeamVariables>`
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

final result = await DefaultConnector.instance.listBuildJobsForTeam(
  teamId: teamId,
  limit: limit,
);
ListBuildJobsForTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
int limit = ...;

final ref = DefaultConnector.instance.listBuildJobsForTeam(
  teamId: teamId,
  limit: limit,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListBuildJobsByWorkflowRun
#### Required Arguments
```dart
String workflowRunId = ...;
DefaultConnector.instance.listBuildJobsByWorkflowRun(
  workflowRunId: workflowRunId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListBuildJobsByWorkflowRunData, ListBuildJobsByWorkflowRunVariables>`
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

final result = await DefaultConnector.instance.listBuildJobsByWorkflowRun(
  workflowRunId: workflowRunId,
);
ListBuildJobsByWorkflowRunData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String workflowRunId = ...;

final ref = DefaultConnector.instance.listBuildJobsByWorkflowRun(
  workflowRunId: workflowRunId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListWaitingBuildJobs
#### Required Arguments
```dart
String workflowRunId = ...;
DefaultConnector.instance.listWaitingBuildJobs(
  workflowRunId: workflowRunId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListWaitingBuildJobsData, ListWaitingBuildJobsVariables>`
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

final result = await DefaultConnector.instance.listWaitingBuildJobs(
  workflowRunId: workflowRunId,
);
ListWaitingBuildJobsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String workflowRunId = ...;

final ref = DefaultConnector.instance.listWaitingBuildJobs(
  workflowRunId: workflowRunId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListBuildLogsForRun
#### Required Arguments
```dart
String buildJobId = ...;
String runId = ...;
String teamId = ...;
DefaultConnector.instance.listBuildLogsForRun(
  buildJobId: buildJobId,
  runId: runId,
  teamId: teamId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For ListBuildLogsForRun, we created `ListBuildLogsForRunBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ListBuildLogsForRunVariablesBuilder {
  ...
   ListBuildLogsForRunVariablesBuilder limit(int? t) {
   _limit.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.listBuildLogsForRun(
  buildJobId: buildJobId,
  runId: runId,
  teamId: teamId,
)
.limit(limit)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<ListBuildLogsForRunData, ListBuildLogsForRunVariables>`
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

final result = await DefaultConnector.instance.listBuildLogsForRun(
  buildJobId: buildJobId,
  runId: runId,
  teamId: teamId,
);
ListBuildLogsForRunData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String buildJobId = ...;
String runId = ...;
String teamId = ...;

final ref = DefaultConnector.instance.listBuildLogsForRun(
  buildJobId: buildJobId,
  runId: runId,
  teamId: teamId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListLatestBuildLogs
#### Required Arguments
```dart
String buildJobId = ...;
String runId = ...;
int limit = ...;
DefaultConnector.instance.listLatestBuildLogs(
  buildJobId: buildJobId,
  runId: runId,
  limit: limit,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListLatestBuildLogsData, ListLatestBuildLogsVariables>`
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

final result = await DefaultConnector.instance.listLatestBuildLogs(
  buildJobId: buildJobId,
  runId: runId,
  limit: limit,
);
ListLatestBuildLogsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String buildJobId = ...;
String runId = ...;
int limit = ...;

final ref = DefaultConnector.instance.listLatestBuildLogs(
  buildJobId: buildJobId,
  runId: runId,
  limit: limit,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateInvitation
#### Required Arguments
```dart
String email = ...;
String teamId = ...;
String teamNameSnapshot = ...;
String token = ...;
Timestamp expiresAt = ...;
DefaultConnector.instance.createInvitation(
  email: email,
  teamId: teamId,
  teamNameSnapshot: teamNameSnapshot,
  token: token,
  expiresAt: expiresAt,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateInvitationData, CreateInvitationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.createInvitation(
  email: email,
  teamId: teamId,
  teamNameSnapshot: teamNameSnapshot,
  token: token,
  expiresAt: expiresAt,
);
CreateInvitationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String email = ...;
String teamId = ...;
String teamNameSnapshot = ...;
String token = ...;
Timestamp expiresAt = ...;

final ref = DefaultConnector.instance.createInvitation(
  email: email,
  teamId: teamId,
  teamNameSnapshot: teamNameSnapshot,
  token: token,
  expiresAt: expiresAt,
).ref();
ref.execute();
```


### ReinviteInvitation
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
String token = ...;
Timestamp expiresAt = ...;
DefaultConnector.instance.reinviteInvitation(
  id: id,
  teamId: teamId,
  token: token,
  expiresAt: expiresAt,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<ReinviteInvitationData, ReinviteInvitationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.reinviteInvitation(
  id: id,
  teamId: teamId,
  token: token,
  expiresAt: expiresAt,
);
ReinviteInvitationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
String token = ...;
Timestamp expiresAt = ...;

final ref = DefaultConnector.instance.reinviteInvitation(
  id: id,
  teamId: teamId,
  token: token,
  expiresAt: expiresAt,
).ref();
ref.execute();
```


### AcceptInvitation
#### Required Arguments
```dart
String id = ...;
DefaultConnector.instance.acceptInvitation(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<AcceptInvitationData, AcceptInvitationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.acceptInvitation(
  id: id,
);
AcceptInvitationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = DefaultConnector.instance.acceptInvitation(
  id: id,
).ref();
ref.execute();
```


### ExpireInvitation
#### Required Arguments
```dart
String id = ...;
DefaultConnector.instance.expireInvitation(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<ExpireInvitationData, ExpireInvitationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.expireInvitation(
  id: id,
);
ExpireInvitationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = DefaultConnector.instance.expireInvitation(
  id: id,
).ref();
ref.execute();
```


### AcceptInvitationAndJoinTeam
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
DefaultConnector.instance.acceptInvitationAndJoinTeam(
  id: id,
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<AcceptInvitationAndJoinTeamData, AcceptInvitationAndJoinTeamVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.acceptInvitationAndJoinTeam(
  id: id,
  teamId: teamId,
);
AcceptInvitationAndJoinTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;

final ref = DefaultConnector.instance.acceptInvitationAndJoinTeam(
  id: id,
  teamId: teamId,
).ref();
ref.execute();
```


### LinkGitHubInstallation
#### Required Arguments
```dart
String teamId = ...;
int installationId = ...;
DefaultConnector.instance.linkGitHubInstallation(
  teamId: teamId,
  installationId: installationId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<LinkGitHubInstallationData, LinkGitHubInstallationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.linkGitHubInstallation(
  teamId: teamId,
  installationId: installationId,
);
LinkGitHubInstallationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
int installationId = ...;

final ref = DefaultConnector.instance.linkGitHubInstallation(
  teamId: teamId,
  installationId: installationId,
).ref();
ref.execute();
```


### UpsertUserProfile
#### Required Arguments
```dart
String id = ...;
String email = ...;
DefaultConnector.instance.upsertUserProfile(
  id: id,
  email: email,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertUserProfile, we created `UpsertUserProfileBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertUserProfileVariablesBuilder {
  ...
   UpsertUserProfileVariablesBuilder displayName(String? t) {
   _displayName.value = t;
   return this;
  }
  UpsertUserProfileVariablesBuilder photoUrl(String? t) {
   _photoUrl.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.upsertUserProfile(
  id: id,
  email: email,
)
.displayName(displayName)
.photoUrl(photoUrl)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertUserProfileData, UpsertUserProfileVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertUserProfile(
  id: id,
  email: email,
);
UpsertUserProfileData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String email = ...;

final ref = DefaultConnector.instance.upsertUserProfile(
  id: id,
  email: email,
).ref();
ref.execute();
```


### UpdateCurrentUserSelectedTeam
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.updateCurrentUserSelectedTeam(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateCurrentUserSelectedTeamData, UpdateCurrentUserSelectedTeamVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateCurrentUserSelectedTeam(
  teamId: teamId,
);
UpdateCurrentUserSelectedTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.updateCurrentUserSelectedTeam(
  teamId: teamId,
).ref();
ref.execute();
```


### UpdateCurrentUserNotificationPreference
#### Required Arguments
```dart
String notificationPreference = ...;
DefaultConnector.instance.updateCurrentUserNotificationPreference(
  notificationPreference: notificationPreference,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateCurrentUserNotificationPreferenceData, UpdateCurrentUserNotificationPreferenceVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateCurrentUserNotificationPreference(
  notificationPreference: notificationPreference,
);
UpdateCurrentUserNotificationPreferenceData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String notificationPreference = ...;

final ref = DefaultConnector.instance.updateCurrentUserNotificationPreference(
  notificationPreference: notificationPreference,
).ref();
ref.execute();
```


### UpdateCurrentUserFcmTokens
#### Required Arguments
```dart
String fcmTokens = ...;
DefaultConnector.instance.updateCurrentUserFcmTokens(
  fcmTokens: fcmTokens,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateCurrentUserFcmTokensData, UpdateCurrentUserFcmTokensVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateCurrentUserFcmTokens(
  fcmTokens: fcmTokens,
);
UpdateCurrentUserFcmTokensData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String fcmTokens = ...;

final ref = DefaultConnector.instance.updateCurrentUserFcmTokens(
  fcmTokens: fcmTokens,
).ref();
ref.execute();
```


### AddCurrentUserFcmToken
#### Required Arguments
```dart
String token = ...;
DefaultConnector.instance.addCurrentUserFcmToken(
  token: token,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<AddCurrentUserFcmTokenData, AddCurrentUserFcmTokenVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.addCurrentUserFcmToken(
  token: token,
);
AddCurrentUserFcmTokenData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String token = ...;

final ref = DefaultConnector.instance.addCurrentUserFcmToken(
  token: token,
).ref();
ref.execute();
```


### UpdateCurrentUserRepositorySelection
#### Required Arguments
```dart
String repository = ...;
String branch = ...;
DefaultConnector.instance.updateCurrentUserRepositorySelection(
  repository: repository,
  branch: branch,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateCurrentUserRepositorySelectionData, UpdateCurrentUserRepositorySelectionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateCurrentUserRepositorySelection(
  repository: repository,
  branch: branch,
);
UpdateCurrentUserRepositorySelectionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String repository = ...;
String branch = ...;

final ref = DefaultConnector.instance.updateCurrentUserRepositorySelection(
  repository: repository,
  branch: branch,
).ref();
ref.execute();
```


### UpdateCurrentUserSelectedBranch
#### Required Arguments
```dart
String branch = ...;
DefaultConnector.instance.updateCurrentUserSelectedBranch(
  branch: branch,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateCurrentUserSelectedBranchData, UpdateCurrentUserSelectedBranchVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateCurrentUserSelectedBranch(
  branch: branch,
);
UpdateCurrentUserSelectedBranchData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String branch = ...;

final ref = DefaultConnector.instance.updateCurrentUserSelectedBranch(
  branch: branch,
).ref();
ref.execute();
```


### UpsertUserFromFirestore
#### Required Arguments
```dart
String id = ...;
String email = ...;
DefaultConnector.instance.upsertUserFromFirestore(
  id: id,
  email: email,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertUserFromFirestore, we created `UpsertUserFromFirestoreBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertUserFromFirestoreVariablesBuilder {
  ...
   UpsertUserFromFirestoreVariablesBuilder displayName(String? t) {
   _displayName.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder photoUrl(String? t) {
   _photoUrl.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder notificationPreference(String? t) {
   _notificationPreference.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder fcmTokens(List<String>? t) {
   _fcmTokens.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder selectedTeamId(String? t) {
   _selectedTeamId.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder selectedRepository(String? t) {
   _selectedRepository.value = t;
   return this;
  }
  UpsertUserFromFirestoreVariablesBuilder selectedBranch(String? t) {
   _selectedBranch.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.upsertUserFromFirestore(
  id: id,
  email: email,
)
.displayName(displayName)
.photoUrl(photoUrl)
.notificationPreference(notificationPreference)
.fcmTokens(fcmTokens)
.selectedTeamId(selectedTeamId)
.selectedRepository(selectedRepository)
.selectedBranch(selectedBranch)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertUserFromFirestoreData, UpsertUserFromFirestoreVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertUserFromFirestore(
  id: id,
  email: email,
);
UpsertUserFromFirestoreData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String email = ...;

final ref = DefaultConnector.instance.upsertUserFromFirestore(
  id: id,
  email: email,
).ref();
ref.execute();
```


### UpsertTeamFromFirestore
#### Required Arguments
```dart
String id = ...;
String name = ...;
DefaultConnector.instance.upsertTeamFromFirestore(
  id: id,
  name: name,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertTeamFromFirestore, we created `UpsertTeamFromFirestoreBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertTeamFromFirestoreVariablesBuilder {
  ...
   UpsertTeamFromFirestoreVariablesBuilder aiEnabled(bool? t) {
   _aiEnabled.value = t;
   return this;
  }
  UpsertTeamFromFirestoreVariablesBuilder githubApiBaseUrl(String? t) {
   _githubApiBaseUrl.value = t;
   return this;
  }
  UpsertTeamFromFirestoreVariablesBuilder githubBaseUrl(String? t) {
   _githubBaseUrl.value = t;
   return this;
  }
  UpsertTeamFromFirestoreVariablesBuilder installationIds(List<int>? t) {
   _installationIds.value = t;
   return this;
  }
  UpsertTeamFromFirestoreVariablesBuilder members(List<String>? t) {
   _members.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.upsertTeamFromFirestore(
  id: id,
  name: name,
)
.aiEnabled(aiEnabled)
.githubApiBaseUrl(githubApiBaseUrl)
.githubBaseUrl(githubBaseUrl)
.installationIds(installationIds)
.members(members)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertTeamFromFirestoreData, UpsertTeamFromFirestoreVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertTeamFromFirestore(
  id: id,
  name: name,
);
UpsertTeamFromFirestoreData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String name = ...;

final ref = DefaultConnector.instance.upsertTeamFromFirestore(
  id: id,
  name: name,
).ref();
ref.execute();
```


### CreateTeamForCurrentUser
#### Required Arguments
```dart
String id = ...;
String name = ...;
DefaultConnector.instance.createTeamForCurrentUser(
  id: id,
  name: name,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateTeamForCurrentUserData, CreateTeamForCurrentUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.createTeamForCurrentUser(
  id: id,
  name: name,
);
CreateTeamForCurrentUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String name = ...;

final ref = DefaultConnector.instance.createTeamForCurrentUser(
  id: id,
  name: name,
).ref();
ref.execute();
```


### UpdateTeamName
#### Required Arguments
```dart
String teamId = ...;
String name = ...;
DefaultConnector.instance.updateTeamName(
  teamId: teamId,
  name: name,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateTeamNameData, UpdateTeamNameVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateTeamName(
  teamId: teamId,
  name: name,
);
UpdateTeamNameData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String name = ...;

final ref = DefaultConnector.instance.updateTeamName(
  teamId: teamId,
  name: name,
).ref();
ref.execute();
```


### UpdateTeamAiEnabled
#### Required Arguments
```dart
String teamId = ...;
bool aiEnabled = ...;
DefaultConnector.instance.updateTeamAiEnabled(
  teamId: teamId,
  aiEnabled: aiEnabled,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateTeamAiEnabledData, UpdateTeamAiEnabledVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateTeamAiEnabled(
  teamId: teamId,
  aiEnabled: aiEnabled,
);
UpdateTeamAiEnabledData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
bool aiEnabled = ...;

final ref = DefaultConnector.instance.updateTeamAiEnabled(
  teamId: teamId,
  aiEnabled: aiEnabled,
).ref();
ref.execute();
```


### UpdateTeamGitHubSettings
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.updateTeamGitHubSettings(
  teamId: teamId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateTeamGitHubSettings, we created `UpdateTeamGitHubSettingsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateTeamGitHubSettingsVariablesBuilder {
  ...
   UpdateTeamGitHubSettingsVariablesBuilder githubBaseUrl(String? t) {
   _githubBaseUrl.value = t;
   return this;
  }
  UpdateTeamGitHubSettingsVariablesBuilder githubApiBaseUrl(String? t) {
   _githubApiBaseUrl.value = t;
   return this;
  }
  UpdateTeamGitHubSettingsVariablesBuilder installationIds(List<int>? t) {
   _installationIds.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.updateTeamGitHubSettings(
  teamId: teamId,
)
.githubBaseUrl(githubBaseUrl)
.githubApiBaseUrl(githubApiBaseUrl)
.installationIds(installationIds)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateTeamGitHubSettingsData, UpdateTeamGitHubSettingsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateTeamGitHubSettings(
  teamId: teamId,
);
UpdateTeamGitHubSettingsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.updateTeamGitHubSettings(
  teamId: teamId,
).ref();
ref.execute();
```


### DeleteTeam
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.deleteTeam(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteTeamData, DeleteTeamVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.deleteTeam(
  teamId: teamId,
);
DeleteTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.deleteTeam(
  teamId: teamId,
).ref();
ref.execute();
```


### UpsertTeamMemberFromFirestore
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
String email = ...;
DefaultConnector.instance.upsertTeamMemberFromFirestore(
  teamId: teamId,
  userId: userId,
  email: email,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpsertTeamMemberFromFirestoreData, UpsertTeamMemberFromFirestoreVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertTeamMemberFromFirestore(
  teamId: teamId,
  userId: userId,
  email: email,
);
UpsertTeamMemberFromFirestoreData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;
String email = ...;

final ref = DefaultConnector.instance.upsertTeamMemberFromFirestore(
  teamId: teamId,
  userId: userId,
  email: email,
).ref();
ref.execute();
```


### UpdateUserFcmTokens
#### Required Arguments
```dart
String id = ...;
String fcmTokens = ...;
DefaultConnector.instance.updateUserFcmTokens(
  id: id,
  fcmTokens: fcmTokens,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateUserFcmTokensData, UpdateUserFcmTokensVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateUserFcmTokens(
  id: id,
  fcmTokens: fcmTokens,
);
UpdateUserFcmTokensData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String fcmTokens = ...;

final ref = DefaultConnector.instance.updateUserFcmTokens(
  id: id,
  fcmTokens: fcmTokens,
).ref();
ref.execute();
```


### AddTeamMember
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
String email = ...;
DefaultConnector.instance.addTeamMember(
  teamId: teamId,
  userId: userId,
  email: email,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<AddTeamMemberData, AddTeamMemberVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.addTeamMember(
  teamId: teamId,
  userId: userId,
  email: email,
);
AddTeamMemberData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;
String email = ...;

final ref = DefaultConnector.instance.addTeamMember(
  teamId: teamId,
  userId: userId,
  email: email,
).ref();
ref.execute();
```


### CreateSecretMetadata
#### Required Arguments
```dart
String id = ...;
String name = ...;
String teamId = ...;
String pathToSecret = ...;
DefaultConnector.instance.createSecretMetadata(
  id: id,
  name: name,
  teamId: teamId,
  pathToSecret: pathToSecret,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateSecretMetadataData, CreateSecretMetadataVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.createSecretMetadata(
  id: id,
  name: name,
  teamId: teamId,
  pathToSecret: pathToSecret,
);
CreateSecretMetadataData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String name = ...;
String teamId = ...;
String pathToSecret = ...;

final ref = DefaultConnector.instance.createSecretMetadata(
  id: id,
  name: name,
  teamId: teamId,
  pathToSecret: pathToSecret,
).ref();
ref.execute();
```


### UpsertSecretMetadataFromFirestore
#### Required Arguments
```dart
String id = ...;
String name = ...;
String teamId = ...;
DefaultConnector.instance.upsertSecretMetadataFromFirestore(
  id: id,
  name: name,
  teamId: teamId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertSecretMetadataFromFirestore, we created `UpsertSecretMetadataFromFirestoreBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertSecretMetadataFromFirestoreVariablesBuilder {
  ...
   UpsertSecretMetadataFromFirestoreVariablesBuilder pathToSecret(String? t) {
   _pathToSecret.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.upsertSecretMetadataFromFirestore(
  id: id,
  name: name,
  teamId: teamId,
)
.pathToSecret(pathToSecret)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertSecretMetadataFromFirestoreData, UpsertSecretMetadataFromFirestoreVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertSecretMetadataFromFirestore(
  id: id,
  name: name,
  teamId: teamId,
);
UpsertSecretMetadataFromFirestoreData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String name = ...;
String teamId = ...;

final ref = DefaultConnector.instance.upsertSecretMetadataFromFirestore(
  id: id,
  name: name,
  teamId: teamId,
).ref();
ref.execute();
```


### UpsertEnvironmentVariableFromFirestore
#### Required Arguments
```dart
String id = ...;
String envKey = ...;
String value = ...;
String teamId = ...;
DefaultConnector.instance.upsertEnvironmentVariableFromFirestore(
  id: id,
  envKey: envKey,
  value: value,
  teamId: teamId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertEnvironmentVariableFromFirestore, we created `UpsertEnvironmentVariableFromFirestoreBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertEnvironmentVariableFromFirestoreVariablesBuilder {
  ...
   UpsertEnvironmentVariableFromFirestoreVariablesBuilder autoIncrement(bool? t) {
   _autoIncrement.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.upsertEnvironmentVariableFromFirestore(
  id: id,
  envKey: envKey,
  value: value,
  teamId: teamId,
)
.autoIncrement(autoIncrement)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertEnvironmentVariableFromFirestoreData, UpsertEnvironmentVariableFromFirestoreVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertEnvironmentVariableFromFirestore(
  id: id,
  envKey: envKey,
  value: value,
  teamId: teamId,
);
UpsertEnvironmentVariableFromFirestoreData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String envKey = ...;
String value = ...;
String teamId = ...;

final ref = DefaultConnector.instance.upsertEnvironmentVariableFromFirestore(
  id: id,
  envKey: envKey,
  value: value,
  teamId: teamId,
).ref();
ref.execute();
```


### CreateEnvironmentVariable
#### Required Arguments
```dart
String id = ...;
String envKey = ...;
String value = ...;
String teamId = ...;
DefaultConnector.instance.createEnvironmentVariable(
  id: id,
  envKey: envKey,
  value: value,
  teamId: teamId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateEnvironmentVariable, we created `CreateEnvironmentVariableBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateEnvironmentVariableVariablesBuilder {
  ...
   CreateEnvironmentVariableVariablesBuilder autoIncrement(bool? t) {
   _autoIncrement.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.createEnvironmentVariable(
  id: id,
  envKey: envKey,
  value: value,
  teamId: teamId,
)
.autoIncrement(autoIncrement)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateEnvironmentVariableData, CreateEnvironmentVariableVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.createEnvironmentVariable(
  id: id,
  envKey: envKey,
  value: value,
  teamId: teamId,
);
CreateEnvironmentVariableData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String envKey = ...;
String value = ...;
String teamId = ...;

final ref = DefaultConnector.instance.createEnvironmentVariable(
  id: id,
  envKey: envKey,
  value: value,
  teamId: teamId,
).ref();
ref.execute();
```


### UpdateEnvironmentVariable
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
String envKey = ...;
String value = ...;
DefaultConnector.instance.updateEnvironmentVariable(
  id: id,
  teamId: teamId,
  envKey: envKey,
  value: value,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateEnvironmentVariableData, UpdateEnvironmentVariableVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateEnvironmentVariable(
  id: id,
  teamId: teamId,
  envKey: envKey,
  value: value,
);
UpdateEnvironmentVariableData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
String envKey = ...;
String value = ...;

final ref = DefaultConnector.instance.updateEnvironmentVariable(
  id: id,
  teamId: teamId,
  envKey: envKey,
  value: value,
).ref();
ref.execute();
```


### DeleteEnvironmentVariable
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
DefaultConnector.instance.deleteEnvironmentVariable(
  id: id,
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteEnvironmentVariableData, DeleteEnvironmentVariableVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.deleteEnvironmentVariable(
  id: id,
  teamId: teamId,
);
DeleteEnvironmentVariableData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;

final ref = DefaultConnector.instance.deleteEnvironmentVariable(
  id: id,
  teamId: teamId,
).ref();
ref.execute();
```


### UpsertInvitationFromFirestore
#### Required Arguments
```dart
String id = ...;
String email = ...;
String teamId = ...;
String teamNameSnapshot = ...;
String token = ...;
InvitationStatus status = ...;
Timestamp expiresAt = ...;
DefaultConnector.instance.upsertInvitationFromFirestore(
  id: id,
  email: email,
  teamId: teamId,
  teamNameSnapshot: teamNameSnapshot,
  token: token,
  status: status,
  expiresAt: expiresAt,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertInvitationFromFirestore, we created `UpsertInvitationFromFirestoreBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertInvitationFromFirestoreVariablesBuilder {
  ...
   UpsertInvitationFromFirestoreVariablesBuilder invitedById(String? t) {
   _invitedById.value = t;
   return this;
  }
  UpsertInvitationFromFirestoreVariablesBuilder acceptedById(String? t) {
   _acceptedById.value = t;
   return this;
  }
  UpsertInvitationFromFirestoreVariablesBuilder acceptedAt(Timestamp? t) {
   _acceptedAt.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.upsertInvitationFromFirestore(
  id: id,
  email: email,
  teamId: teamId,
  teamNameSnapshot: teamNameSnapshot,
  token: token,
  status: status,
  expiresAt: expiresAt,
)
.invitedById(invitedById)
.acceptedById(acceptedById)
.acceptedAt(acceptedAt)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertInvitationFromFirestoreData, UpsertInvitationFromFirestoreVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertInvitationFromFirestore(
  id: id,
  email: email,
  teamId: teamId,
  teamNameSnapshot: teamNameSnapshot,
  token: token,
  status: status,
  expiresAt: expiresAt,
);
UpsertInvitationFromFirestoreData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String email = ...;
String teamId = ...;
String teamNameSnapshot = ...;
String token = ...;
InvitationStatus status = ...;
Timestamp expiresAt = ...;

final ref = DefaultConnector.instance.upsertInvitationFromFirestore(
  id: id,
  email: email,
  teamId: teamId,
  teamNameSnapshot: teamNameSnapshot,
  token: token,
  status: status,
  expiresAt: expiresAt,
).ref();
ref.execute();
```


### UpdateSecretMetadata
#### Required Arguments
```dart
String id = ...;
String name = ...;
DefaultConnector.instance.updateSecretMetadata(
  id: id,
  name: name,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateSecretMetadataData, UpdateSecretMetadataVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateSecretMetadata(
  id: id,
  name: name,
);
UpdateSecretMetadataData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String name = ...;

final ref = DefaultConnector.instance.updateSecretMetadata(
  id: id,
  name: name,
).ref();
ref.execute();
```


### DeleteSecretMetadata
#### Required Arguments
```dart
String id = ...;
DefaultConnector.instance.deleteSecretMetadata(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteSecretMetadataData, DeleteSecretMetadataVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.deleteSecretMetadata(
  id: id,
);
DeleteSecretMetadataData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = DefaultConnector.instance.deleteSecretMetadata(
  id: id,
).ref();
ref.execute();
```


### UpdateWorkflowSecretKeys
#### Required Arguments
```dart
String id = ...;
AnyValue workflowSteps = ...;
DefaultConnector.instance.updateWorkflowSecretKeys(
  id: id,
  workflowSteps: workflowSteps,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateWorkflowSecretKeysData, UpdateWorkflowSecretKeysVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateWorkflowSecretKeys(
  id: id,
  workflowSteps: workflowSteps,
);
UpdateWorkflowSecretKeysData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
AnyValue workflowSteps = ...;

final ref = DefaultConnector.instance.updateWorkflowSecretKeys(
  id: id,
  workflowSteps: workflowSteps,
).ref();
ref.execute();
```


### UpsertWorkflowFromFirestore
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
DefaultConnector.instance.upsertWorkflowFromFirestore(
  id: id,
  teamId: teamId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertWorkflowFromFirestore, we created `UpsertWorkflowFromFirestoreBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertWorkflowFromFirestoreVariablesBuilder {
  ...
   UpsertWorkflowFromFirestoreVariablesBuilder name(String? t) {
   _name.value = t;
   return this;
  }
  UpsertWorkflowFromFirestoreVariablesBuilder workflowConfig(AnyValue? t) {
   _workflowConfig.value = t;
   return this;
  }
  UpsertWorkflowFromFirestoreVariablesBuilder workflowSteps(AnyValue? t) {
   _workflowSteps.value = t;
   return this;
  }
  UpsertWorkflowFromFirestoreVariablesBuilder isEditing(bool? t) {
   _isEditing.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.upsertWorkflowFromFirestore(
  id: id,
  teamId: teamId,
)
.name(name)
.workflowConfig(workflowConfig)
.workflowSteps(workflowSteps)
.isEditing(isEditing)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertWorkflowFromFirestoreData, UpsertWorkflowFromFirestoreVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertWorkflowFromFirestore(
  id: id,
  teamId: teamId,
);
UpsertWorkflowFromFirestoreData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;

final ref = DefaultConnector.instance.upsertWorkflowFromFirestore(
  id: id,
  teamId: teamId,
).ref();
ref.execute();
```


### CreateWorkflow
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
String name = ...;
AnyValue workflowConfig = ...;
AnyValue workflowSteps = ...;
bool isEditing = ...;
DefaultConnector.instance.createWorkflow(
  id: id,
  teamId: teamId,
  name: name,
  workflowConfig: workflowConfig,
  workflowSteps: workflowSteps,
  isEditing: isEditing,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateWorkflowData, CreateWorkflowVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.createWorkflow(
  id: id,
  teamId: teamId,
  name: name,
  workflowConfig: workflowConfig,
  workflowSteps: workflowSteps,
  isEditing: isEditing,
);
CreateWorkflowData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
String name = ...;
AnyValue workflowConfig = ...;
AnyValue workflowSteps = ...;
bool isEditing = ...;

final ref = DefaultConnector.instance.createWorkflow(
  id: id,
  teamId: teamId,
  name: name,
  workflowConfig: workflowConfig,
  workflowSteps: workflowSteps,
  isEditing: isEditing,
).ref();
ref.execute();
```


### UpdateWorkflowName
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
String name = ...;
DefaultConnector.instance.updateWorkflowName(
  id: id,
  teamId: teamId,
  name: name,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateWorkflowNameData, UpdateWorkflowNameVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateWorkflowName(
  id: id,
  teamId: teamId,
  name: name,
);
UpdateWorkflowNameData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
String name = ...;

final ref = DefaultConnector.instance.updateWorkflowName(
  id: id,
  teamId: teamId,
  name: name,
).ref();
ref.execute();
```


### UpdateWorkflowConfig
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
AnyValue workflowConfig = ...;
DefaultConnector.instance.updateWorkflowConfig(
  id: id,
  teamId: teamId,
  workflowConfig: workflowConfig,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateWorkflowConfigData, UpdateWorkflowConfigVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateWorkflowConfig(
  id: id,
  teamId: teamId,
  workflowConfig: workflowConfig,
);
UpdateWorkflowConfigData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
AnyValue workflowConfig = ...;

final ref = DefaultConnector.instance.updateWorkflowConfig(
  id: id,
  teamId: teamId,
  workflowConfig: workflowConfig,
).ref();
ref.execute();
```


### UpdateWorkflowSteps
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
AnyValue workflowSteps = ...;
DefaultConnector.instance.updateWorkflowSteps(
  id: id,
  teamId: teamId,
  workflowSteps: workflowSteps,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateWorkflowStepsData, UpdateWorkflowStepsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateWorkflowSteps(
  id: id,
  teamId: teamId,
  workflowSteps: workflowSteps,
);
UpdateWorkflowStepsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
AnyValue workflowSteps = ...;

final ref = DefaultConnector.instance.updateWorkflowSteps(
  id: id,
  teamId: teamId,
  workflowSteps: workflowSteps,
).ref();
ref.execute();
```


### DeleteWorkflow
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
DefaultConnector.instance.deleteWorkflow(
  id: id,
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteWorkflowData, DeleteWorkflowVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.deleteWorkflow(
  id: id,
  teamId: teamId,
);
DeleteWorkflowData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;

final ref = DefaultConnector.instance.deleteWorkflow(
  id: id,
  teamId: teamId,
).ref();
ref.execute();
```


### UpsertWorkflowFile
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
String repository = ...;
String branch = ...;
String fileName = ...;
String filePath = ...;
String content = ...;
DefaultConnector.instance.upsertWorkflowFile(
  id: id,
  teamId: teamId,
  repository: repository,
  branch: branch,
  fileName: fileName,
  filePath: filePath,
  content: content,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertWorkflowFile, we created `UpsertWorkflowFileBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertWorkflowFileVariablesBuilder {
  ...
   UpsertWorkflowFileVariablesBuilder enabled(bool? t) {
   _enabled.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.upsertWorkflowFile(
  id: id,
  teamId: teamId,
  repository: repository,
  branch: branch,
  fileName: fileName,
  filePath: filePath,
  content: content,
)
.enabled(enabled)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertWorkflowFileData, UpsertWorkflowFileVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertWorkflowFile(
  id: id,
  teamId: teamId,
  repository: repository,
  branch: branch,
  fileName: fileName,
  filePath: filePath,
  content: content,
);
UpsertWorkflowFileData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
String repository = ...;
String branch = ...;
String fileName = ...;
String filePath = ...;
String content = ...;

final ref = DefaultConnector.instance.upsertWorkflowFile(
  id: id,
  teamId: teamId,
  repository: repository,
  branch: branch,
  fileName: fileName,
  filePath: filePath,
  content: content,
).ref();
ref.execute();
```


### DeleteWorkflowFile
#### Required Arguments
```dart
String id = ...;
DefaultConnector.instance.deleteWorkflowFile(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteWorkflowFileData, DeleteWorkflowFileVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.deleteWorkflowFile(
  id: id,
);
DeleteWorkflowFileData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = DefaultConnector.instance.deleteWorkflowFile(
  id: id,
).ref();
ref.execute();
```


### UpdateWorkflowFileEnabled
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
bool enabled = ...;
DefaultConnector.instance.updateWorkflowFileEnabled(
  id: id,
  teamId: teamId,
  enabled: enabled,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateWorkflowFileEnabledData, UpdateWorkflowFileEnabledVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateWorkflowFileEnabled(
  id: id,
  teamId: teamId,
  enabled: enabled,
);
UpdateWorkflowFileEnabledData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
bool enabled = ...;

final ref = DefaultConnector.instance.updateWorkflowFileEnabled(
  id: id,
  teamId: teamId,
  enabled: enabled,
).ref();
ref.execute();
```


### CreateBuildJob
#### Required Arguments
```dart
String id = ...;
BuildJobStatus status = ...;
String owner = ...;
String repo = ...;
DefaultConnector.instance.createBuildJob(
  id: id,
  status: status,
  owner: owner,
  repo: repo,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateBuildJob, we created `CreateBuildJobBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateBuildJobVariablesBuilder {
  ...
   CreateBuildJobVariablesBuilder teamId(String? t) {
   _teamId.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder workflowId(String? t) {
   _workflowId.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder workflowFileName(String? t) {
   _workflowFileName.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder workflowName(String? t) {
   _workflowName.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder jobKey(String? t) {
   _jobKey.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder workflowRunId(String? t) {
   _workflowRunId.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder needs(List<String>? t) {
   _needs.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder resolvedNeeds(AnyValue? t) {
   _resolvedNeeds.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder installationId(BigInt? t) {
   _installationId.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder installationToken(String? t) {
   _installationToken.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder tokenExpiresAt(Timestamp? t) {
   _tokenExpiresAt.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder checkRunId(BigInt? t) {
   _checkRunId.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder commitSha(String? t) {
   _commitSha.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder pullRequestNumber(int? t) {
   _pullRequestNumber.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder event(String? t) {
   _event.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder action(String? t) {
   _action.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder sender(String? t) {
   _sender.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder repository(String? t) {
   _repository.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder tagName(String? t) {
   _tagName.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder branch(String? t) {
   _branch.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder releaseName(String? t) {
   _releaseName.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder runsOn(String? t) {
   _runsOn.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder runCount(int? t) {
   _runCount.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder latestRunId(String? t) {
   _latestRunId.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder retriedFromBuildJobId(String? t) {
   _retriedFromBuildJobId.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder retriedFromWorkflowRunId(String? t) {
   _retriedFromWorkflowRunId.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder githubApiBaseUrl(String? t) {
   _githubApiBaseUrl.value = t;
   return this;
  }
  CreateBuildJobVariablesBuilder githubBaseUrl(String? t) {
   _githubBaseUrl.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.createBuildJob(
  id: id,
  status: status,
  owner: owner,
  repo: repo,
)
.teamId(teamId)
.workflowId(workflowId)
.workflowFileName(workflowFileName)
.workflowName(workflowName)
.jobKey(jobKey)
.workflowRunId(workflowRunId)
.needs(needs)
.resolvedNeeds(resolvedNeeds)
.installationId(installationId)
.installationToken(installationToken)
.tokenExpiresAt(tokenExpiresAt)
.checkRunId(checkRunId)
.commitSha(commitSha)
.pullRequestNumber(pullRequestNumber)
.event(event)
.action(action)
.sender(sender)
.repository(repository)
.tagName(tagName)
.branch(branch)
.releaseName(releaseName)
.runsOn(runsOn)
.runCount(runCount)
.latestRunId(latestRunId)
.retriedFromBuildJobId(retriedFromBuildJobId)
.retriedFromWorkflowRunId(retriedFromWorkflowRunId)
.githubApiBaseUrl(githubApiBaseUrl)
.githubBaseUrl(githubBaseUrl)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateBuildJobData, CreateBuildJobVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.createBuildJob(
  id: id,
  status: status,
  owner: owner,
  repo: repo,
);
CreateBuildJobData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
BuildJobStatus status = ...;
String owner = ...;
String repo = ...;

final ref = DefaultConnector.instance.createBuildJob(
  id: id,
  status: status,
  owner: owner,
  repo: repo,
).ref();
ref.execute();
```


### UpsertBuildJobFromFirestore
#### Required Arguments
```dart
String id = ...;
BuildJobStatus status = ...;
String owner = ...;
String repo = ...;
DefaultConnector.instance.upsertBuildJobFromFirestore(
  id: id,
  status: status,
  owner: owner,
  repo: repo,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpsertBuildJobFromFirestore, we created `UpsertBuildJobFromFirestoreBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpsertBuildJobFromFirestoreVariablesBuilder {
  ...
   UpsertBuildJobFromFirestoreVariablesBuilder teamId(String? t) {
   _teamId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder workflowId(String? t) {
   _workflowId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder workflowFileName(String? t) {
   _workflowFileName.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder workflowName(String? t) {
   _workflowName.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder jobKey(String? t) {
   _jobKey.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder workflowRunId(String? t) {
   _workflowRunId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder needs(List<String>? t) {
   _needs.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder resolvedNeeds(AnyValue? t) {
   _resolvedNeeds.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder installationId(BigInt? t) {
   _installationId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder installationToken(String? t) {
   _installationToken.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder tokenExpiresAt(Timestamp? t) {
   _tokenExpiresAt.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder checkRunId(BigInt? t) {
   _checkRunId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder commitSha(String? t) {
   _commitSha.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder pullRequestNumber(int? t) {
   _pullRequestNumber.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder event(String? t) {
   _event.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder action(String? t) {
   _action.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder sender(String? t) {
   _sender.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder repository(String? t) {
   _repository.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder tagName(String? t) {
   _tagName.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder branch(String? t) {
   _branch.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder releaseName(String? t) {
   _releaseName.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder runsOn(String? t) {
   _runsOn.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder runCount(int? t) {
   _runCount.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder latestRunId(String? t) {
   _latestRunId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder retriedFromBuildJobId(String? t) {
   _retriedFromBuildJobId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder retriedFromWorkflowRunId(String? t) {
   _retriedFromWorkflowRunId.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder githubApiBaseUrl(String? t) {
   _githubApiBaseUrl.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder githubBaseUrl(String? t) {
   _githubBaseUrl.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder failureSummaryStatus(String? t) {
   _failureSummaryStatus.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder failureSummary(String? t) {
   _failureSummary.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder failureSummaryModel(String? t) {
   _failureSummaryModel.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder failureSummaryDurationMs(int? t) {
   _failureSummaryDurationMs.value = t;
   return this;
  }
  UpsertBuildJobFromFirestoreVariablesBuilder completedAt(Timestamp? t) {
   _completedAt.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.upsertBuildJobFromFirestore(
  id: id,
  status: status,
  owner: owner,
  repo: repo,
)
.teamId(teamId)
.workflowId(workflowId)
.workflowFileName(workflowFileName)
.workflowName(workflowName)
.jobKey(jobKey)
.workflowRunId(workflowRunId)
.needs(needs)
.resolvedNeeds(resolvedNeeds)
.installationId(installationId)
.installationToken(installationToken)
.tokenExpiresAt(tokenExpiresAt)
.checkRunId(checkRunId)
.commitSha(commitSha)
.pullRequestNumber(pullRequestNumber)
.event(event)
.action(action)
.sender(sender)
.repository(repository)
.tagName(tagName)
.branch(branch)
.releaseName(releaseName)
.runsOn(runsOn)
.runCount(runCount)
.latestRunId(latestRunId)
.retriedFromBuildJobId(retriedFromBuildJobId)
.retriedFromWorkflowRunId(retriedFromWorkflowRunId)
.githubApiBaseUrl(githubApiBaseUrl)
.githubBaseUrl(githubBaseUrl)
.failureSummaryStatus(failureSummaryStatus)
.failureSummary(failureSummary)
.failureSummaryModel(failureSummaryModel)
.failureSummaryDurationMs(failureSummaryDurationMs)
.completedAt(completedAt)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpsertBuildJobFromFirestoreData, UpsertBuildJobFromFirestoreVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertBuildJobFromFirestore(
  id: id,
  status: status,
  owner: owner,
  repo: repo,
);
UpsertBuildJobFromFirestoreData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
BuildJobStatus status = ...;
String owner = ...;
String repo = ...;

final ref = DefaultConnector.instance.upsertBuildJobFromFirestore(
  id: id,
  status: status,
  owner: owner,
  repo: repo,
).ref();
ref.execute();
```


### UpsertBuildRunFromFirestore
#### Required Arguments
```dart
String buildJobId = ...;
String id = ...;
DefaultConnector.instance.upsertBuildRunFromFirestore(
  buildJobId: buildJobId,
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpsertBuildRunFromFirestoreData, UpsertBuildRunFromFirestoreVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertBuildRunFromFirestore(
  buildJobId: buildJobId,
  id: id,
);
UpsertBuildRunFromFirestoreData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String buildJobId = ...;
String id = ...;

final ref = DefaultConnector.instance.upsertBuildRunFromFirestore(
  buildJobId: buildJobId,
  id: id,
).ref();
ref.execute();
```


### UpsertBuildLogFromFirestore
#### Required Arguments
```dart
String buildJobId = ...;
String runId = ...;
String id = ...;
String message = ...;
Timestamp timestamp = ...;
DefaultConnector.instance.upsertBuildLogFromFirestore(
  buildJobId: buildJobId,
  runId: runId,
  id: id,
  message: message,
  timestamp: timestamp,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpsertBuildLogFromFirestoreData, UpsertBuildLogFromFirestoreVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.upsertBuildLogFromFirestore(
  buildJobId: buildJobId,
  runId: runId,
  id: id,
  message: message,
  timestamp: timestamp,
);
UpsertBuildLogFromFirestoreData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String buildJobId = ...;
String runId = ...;
String id = ...;
String message = ...;
Timestamp timestamp = ...;

final ref = DefaultConnector.instance.upsertBuildLogFromFirestore(
  buildJobId: buildJobId,
  runId: runId,
  id: id,
  message: message,
  timestamp: timestamp,
).ref();
ref.execute();
```


### ClaimQueuedBuildJob
#### Required Arguments
```dart
String runsOnPattern = ...;
DefaultConnector.instance.claimQueuedBuildJob(
  runsOnPattern: runsOnPattern,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<ClaimQueuedBuildJobData, ClaimQueuedBuildJobVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.claimQueuedBuildJob(
  runsOnPattern: runsOnPattern,
);
ClaimQueuedBuildJobData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String runsOnPattern = ...;

final ref = DefaultConnector.instance.claimQueuedBuildJob(
  runsOnPattern: runsOnPattern,
).ref();
ref.execute();
```


### CreateBuildRunForWorker
#### Required Arguments
```dart
String buildJobId = ...;
String id = ...;
DefaultConnector.instance.createBuildRunForWorker(
  buildJobId: buildJobId,
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateBuildRunForWorkerData, CreateBuildRunForWorkerVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.createBuildRunForWorker(
  buildJobId: buildJobId,
  id: id,
);
CreateBuildRunForWorkerData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String buildJobId = ...;
String id = ...;

final ref = DefaultConnector.instance.createBuildRunForWorker(
  buildJobId: buildJobId,
  id: id,
).ref();
ref.execute();
```


### UpdateBuildRunStatusForWorker
#### Required Arguments
```dart
String buildJobId = ...;
String runId = ...;
String status = ...;
DefaultConnector.instance.updateBuildRunStatusForWorker(
  buildJobId: buildJobId,
  runId: runId,
  status: status,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateBuildRunStatusForWorker, we created `UpdateBuildRunStatusForWorkerBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateBuildRunStatusForWorkerVariablesBuilder {
  ...
   UpdateBuildRunStatusForWorkerVariablesBuilder conclusion(String? t) {
   _conclusion.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.updateBuildRunStatusForWorker(
  buildJobId: buildJobId,
  runId: runId,
  status: status,
)
.conclusion(conclusion)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateBuildRunStatusForWorkerData, UpdateBuildRunStatusForWorkerVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateBuildRunStatusForWorker(
  buildJobId: buildJobId,
  runId: runId,
  status: status,
);
UpdateBuildRunStatusForWorkerData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String buildJobId = ...;
String runId = ...;
String status = ...;

final ref = DefaultConnector.instance.updateBuildRunStatusForWorker(
  buildJobId: buildJobId,
  runId: runId,
  status: status,
).ref();
ref.execute();
```


### AppendBuildLogForWorker
#### Required Arguments
```dart
String buildJobId = ...;
String runId = ...;
String id = ...;
String message = ...;
String level = ...;
Timestamp timestamp = ...;
DefaultConnector.instance.appendBuildLogForWorker(
  buildJobId: buildJobId,
  runId: runId,
  id: id,
  message: message,
  level: level,
  timestamp: timestamp,
).execute();
```

#### Optional Arguments
We return a builder for each query. For AppendBuildLogForWorker, we created `AppendBuildLogForWorkerBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class AppendBuildLogForWorkerVariablesBuilder {
  ...
   AppendBuildLogForWorkerVariablesBuilder stackTrace(String? t) {
   _stackTrace.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.appendBuildLogForWorker(
  buildJobId: buildJobId,
  runId: runId,
  id: id,
  message: message,
  level: level,
  timestamp: timestamp,
)
.stackTrace(stackTrace)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<AppendBuildLogForWorkerData, AppendBuildLogForWorkerVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.appendBuildLogForWorker(
  buildJobId: buildJobId,
  runId: runId,
  id: id,
  message: message,
  level: level,
  timestamp: timestamp,
);
AppendBuildLogForWorkerData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String buildJobId = ...;
String runId = ...;
String id = ...;
String message = ...;
String level = ...;
Timestamp timestamp = ...;

final ref = DefaultConnector.instance.appendBuildLogForWorker(
  buildJobId: buildJobId,
  runId: runId,
  id: id,
  message: message,
  level: level,
  timestamp: timestamp,
).ref();
ref.execute();
```


### CompleteBuildJobForWorker
#### Required Arguments
```dart
String id = ...;
BuildJobStatus status = ...;
Timestamp completedAt = ...;
DefaultConnector.instance.completeBuildJobForWorker(
  id: id,
  status: status,
  completedAt: completedAt,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CompleteBuildJobForWorkerData, CompleteBuildJobForWorkerVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.completeBuildJobForWorker(
  id: id,
  status: status,
  completedAt: completedAt,
);
CompleteBuildJobForWorkerData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
BuildJobStatus status = ...;
Timestamp completedAt = ...;

final ref = DefaultConnector.instance.completeBuildJobForWorker(
  id: id,
  status: status,
  completedAt: completedAt,
).ref();
ref.execute();
```


### UpdateEnvironmentVariableValueForWorker
#### Required Arguments
```dart
String id = ...;
String value = ...;
DefaultConnector.instance.updateEnvironmentVariableValueForWorker(
  id: id,
  value: value,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateEnvironmentVariableValueForWorkerData, UpdateEnvironmentVariableValueForWorkerVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateEnvironmentVariableValueForWorker(
  id: id,
  value: value,
);
UpdateEnvironmentVariableValueForWorkerData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String value = ...;

final ref = DefaultConnector.instance.updateEnvironmentVariableValueForWorker(
  id: id,
  value: value,
).ref();
ref.execute();
```


### UpdateBuildJobStatus
#### Required Arguments
```dart
String id = ...;
BuildJobStatus status = ...;
DefaultConnector.instance.updateBuildJobStatus(
  id: id,
  status: status,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateBuildJobStatusData, UpdateBuildJobStatusVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateBuildJobStatus(
  id: id,
  status: status,
);
UpdateBuildJobStatusData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
BuildJobStatus status = ...;

final ref = DefaultConnector.instance.updateBuildJobStatus(
  id: id,
  status: status,
).ref();
ref.execute();
```


### UpdateBuildJobFailureSummary
#### Required Arguments
```dart
String id = ...;
String failureSummaryStatus = ...;
DefaultConnector.instance.updateBuildJobFailureSummary(
  id: id,
  failureSummaryStatus: failureSummaryStatus,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateBuildJobFailureSummary, we created `UpdateBuildJobFailureSummaryBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateBuildJobFailureSummaryVariablesBuilder {
  ...
   UpdateBuildJobFailureSummaryVariablesBuilder failureSummary(String? t) {
   _failureSummary.value = t;
   return this;
  }
  UpdateBuildJobFailureSummaryVariablesBuilder failureSummaryModel(String? t) {
   _failureSummaryModel.value = t;
   return this;
  }
  UpdateBuildJobFailureSummaryVariablesBuilder failureSummaryDurationMs(int? t) {
   _failureSummaryDurationMs.value = t;
   return this;
  }

  ...
}
DefaultConnector.instance.updateBuildJobFailureSummary(
  id: id,
  failureSummaryStatus: failureSummaryStatus,
)
.failureSummary(failureSummary)
.failureSummaryModel(failureSummaryModel)
.failureSummaryDurationMs(failureSummaryDurationMs)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateBuildJobFailureSummaryData, UpdateBuildJobFailureSummaryVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DefaultConnector.instance.updateBuildJobFailureSummary(
  id: id,
  failureSummaryStatus: failureSummaryStatus,
);
UpdateBuildJobFailureSummaryData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String failureSummaryStatus = ...;

final ref = DefaultConnector.instance.updateBuildJobFailureSummary(
  id: id,
  failureSummaryStatus: failureSummaryStatus,
).ref();
ref.execute();
```

