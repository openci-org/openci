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


### AddTeamMember
#### Required Arguments
```dart
String teamId = ...;
DefaultConnector.instance.addTeamMember(
  teamId: teamId,
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
);
AddTeamMemberData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = DefaultConnector.instance.addTeamMember(
  teamId: teamId,
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

