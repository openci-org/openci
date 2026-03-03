# dataconnect_generated SDK

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
DashboardConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetMyUser
#### Required Arguments
```dart
// No required arguments
DashboardConnector.instance.getMyUser().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyUserData, void>`
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

final result = await DashboardConnector.instance.getMyUser();
GetMyUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = DashboardConnector.instance.getMyUser().ref();
ref.execute();

ref.subscribe(...);
```


### GetMyTeams
#### Required Arguments
```dart
String uid = ...;
DashboardConnector.instance.getMyTeams(
  uid: uid,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyTeamsData, GetMyTeamsVariables>`
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

final result = await DashboardConnector.instance.getMyTeams(
  uid: uid,
);
GetMyTeamsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;

final ref = DashboardConnector.instance.getMyTeams(
  uid: uid,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateUserWithDefaultTeam
#### Required Arguments
```dart
String uid = ...;
DashboardConnector.instance.createUserWithDefaultTeam(
  uid: uid,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateUserWithDefaultTeam, we created `CreateUserWithDefaultTeamBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateUserWithDefaultTeamVariablesBuilder {
  ...
 
  CreateUserWithDefaultTeamVariablesBuilder teamName(String t) {
   _teamName.value = t;
   return this;
  }

  ...
}
DashboardConnector.instance.createUserWithDefaultTeam(
  uid: uid,
)
.teamName(teamName)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateUserWithDefaultTeamData, CreateUserWithDefaultTeamVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DashboardConnector.instance.createUserWithDefaultTeam(
  uid: uid,
);
CreateUserWithDefaultTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String uid = ...;

final ref = DashboardConnector.instance.createUserWithDefaultTeam(
  uid: uid,
).ref();
ref.execute();
```


### CreateTeam
#### Required Arguments
```dart
String teamName = ...;
String uid = ...;
DashboardConnector.instance.createTeam(
  teamName: teamName,
  uid: uid,
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

final result = await DashboardConnector.instance.createTeam(
  teamName: teamName,
  uid: uid,
);
CreateTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamName = ...;
String uid = ...;

final ref = DashboardConnector.instance.createTeam(
  teamName: teamName,
  uid: uid,
).ref();
ref.execute();
```


### UpdateTeamName
#### Required Arguments
```dart
String teamId = ...;
String newName = ...;
DashboardConnector.instance.updateTeamName(
  teamId: teamId,
  newName: newName,
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

final result = await DashboardConnector.instance.updateTeamName(
  teamId: teamId,
  newName: newName,
);
UpdateTeamNameData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String newName = ...;

final ref = DashboardConnector.instance.updateTeamName(
  teamId: teamId,
  newName: newName,
).ref();
ref.execute();
```


### UpdateNotificationPreference
#### Required Arguments
```dart
NotificationPreference preference = ...;
DashboardConnector.instance.updateNotificationPreference(
  preference: preference,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateNotificationPreferenceData, UpdateNotificationPreferenceVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DashboardConnector.instance.updateNotificationPreference(
  preference: preference,
);
UpdateNotificationPreferenceData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
NotificationPreference preference = ...;

final ref = DashboardConnector.instance.updateNotificationPreference(
  preference: preference,
).ref();
ref.execute();
```


### AddFcmToken
#### Required Arguments
```dart
String token = ...;
DashboardConnector.instance.addFcmToken(
  token: token,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<AddFcmTokenData, AddFcmTokenVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await DashboardConnector.instance.addFcmToken(
  token: token,
);
AddFcmTokenData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String token = ...;

final ref = DashboardConnector.instance.addFcmToken(
  token: token,
).ref();
ref.execute();
```

