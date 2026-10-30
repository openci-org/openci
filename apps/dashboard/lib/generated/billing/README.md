# billing SDK

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
BillingConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetBillingAdmission
#### Required Arguments
```dart
String teamId = ...;
String id = ...;
BillingConnector.instance.getBillingAdmission(
  teamId: teamId,
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingAdmissionData, GetBillingAdmissionVariables>`
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

final result = await BillingConnector.instance.getBillingAdmission(
  teamId: teamId,
  id: id,
);
GetBillingAdmissionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String id = ...;

final ref = BillingConnector.instance.getBillingAdmission(
  teamId: teamId,
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetOpenBillingCheckoutCreation
#### Required Arguments
```dart
String teamId = ...;
bool livemode = ...;
BillingConnector.instance.getOpenBillingCheckoutCreation(
  teamId: teamId,
  livemode: livemode,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetOpenBillingCheckoutCreationData, GetOpenBillingCheckoutCreationVariables>`
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

final result = await BillingConnector.instance.getOpenBillingCheckoutCreation(
  teamId: teamId,
  livemode: livemode,
);
GetOpenBillingCheckoutCreationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
bool livemode = ...;

final ref = BillingConnector.instance.getOpenBillingCheckoutCreation(
  teamId: teamId,
  livemode: livemode,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingContext
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
BillingConnector.instance.getBillingContext(
  teamId: teamId,
  userId: userId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingContextData, GetBillingContextVariables>`
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

final result = await BillingConnector.instance.getBillingContext(
  teamId: teamId,
  userId: userId,
);
GetBillingContextData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;

final ref = BillingConnector.instance.getBillingContext(
  teamId: teamId,
  userId: userId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingMembership
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
BillingConnector.instance.getBillingMembership(
  teamId: teamId,
  userId: userId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingMembershipData, GetBillingMembershipVariables>`
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

final result = await BillingConnector.instance.getBillingMembership(
  teamId: teamId,
  userId: userId,
);
GetBillingMembershipData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;

final ref = BillingConnector.instance.getBillingMembership(
  teamId: teamId,
  userId: userId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingCustomerByStripeId
#### Required Arguments
```dart
String stripeCustomerId = ...;
bool livemode = ...;
BillingConnector.instance.getBillingCustomerByStripeId(
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingCustomerByStripeIdData, GetBillingCustomerByStripeIdVariables>`
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

final result = await BillingConnector.instance.getBillingCustomerByStripeId(
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
);
GetBillingCustomerByStripeIdData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String stripeCustomerId = ...;
bool livemode = ...;

final ref = BillingConnector.instance.getBillingCustomerByStripeId(
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingCheckoutCreation
#### Required Arguments
```dart
String teamId = ...;
String idempotencyKey = ...;
bool livemode = ...;
BillingConnector.instance.getBillingCheckoutCreation(
  teamId: teamId,
  idempotencyKey: idempotencyKey,
  livemode: livemode,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingCheckoutCreationData, GetBillingCheckoutCreationVariables>`
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

final result = await BillingConnector.instance.getBillingCheckoutCreation(
  teamId: teamId,
  idempotencyKey: idempotencyKey,
  livemode: livemode,
);
GetBillingCheckoutCreationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String idempotencyKey = ...;
bool livemode = ...;

final ref = BillingConnector.instance.getBillingCheckoutCreation(
  teamId: teamId,
  idempotencyKey: idempotencyKey,
  livemode: livemode,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingPeriod
#### Required Arguments
```dart
String teamId = ...;
String id = ...;
BillingConnector.instance.getBillingPeriod(
  teamId: teamId,
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingPeriodData, GetBillingPeriodVariables>`
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

final result = await BillingConnector.instance.getBillingPeriod(
  teamId: teamId,
  id: id,
);
GetBillingPeriodData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String id = ...;

final ref = BillingConnector.instance.getBillingPeriod(
  teamId: teamId,
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingCustomerCreation
#### Required Arguments
```dart
String teamId = ...;
bool livemode = ...;
BillingConnector.instance.getBillingCustomerCreation(
  teamId: teamId,
  livemode: livemode,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingCustomerCreationData, GetBillingCustomerCreationVariables>`
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

final result = await BillingConnector.instance.getBillingCustomerCreation(
  teamId: teamId,
  livemode: livemode,
);
GetBillingCustomerCreationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
bool livemode = ...;

final ref = BillingConnector.instance.getBillingCustomerCreation(
  teamId: teamId,
  livemode: livemode,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingTeamDeletion
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
BillingConnector.instance.getBillingTeamDeletion(
  teamId: teamId,
  userId: userId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingTeamDeletionData, GetBillingTeamDeletionVariables>`
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

final result = await BillingConnector.instance.getBillingTeamDeletion(
  teamId: teamId,
  userId: userId,
);
GetBillingTeamDeletionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;

final ref = BillingConnector.instance.getBillingTeamDeletion(
  teamId: teamId,
  userId: userId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetDueBillingTeamDeletions
#### Required Arguments
```dart
// No required arguments
BillingConnector.instance.getDueBillingTeamDeletions().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetDueBillingTeamDeletionsData, void>`
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

final result = await BillingConnector.instance.getDueBillingTeamDeletions();
GetDueBillingTeamDeletionsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = BillingConnector.instance.getDueBillingTeamDeletions().ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingExecution
#### Required Arguments
```dart
String teamId = ...;
String runId = ...;
BillingConnector.instance.getBillingExecution(
  teamId: teamId,
  runId: runId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingExecutionData, GetBillingExecutionVariables>`
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

final result = await BillingConnector.instance.getBillingExecution(
  teamId: teamId,
  runId: runId,
);
GetBillingExecutionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String runId = ...;

final ref = BillingConnector.instance.getBillingExecution(
  teamId: teamId,
  runId: runId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetExpiredBillingWork
#### Required Arguments
```dart
BigInt atMs = ...;
BillingConnector.instance.getExpiredBillingWork(
  atMs: atMs,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetExpiredBillingWorkData, GetExpiredBillingWorkVariables>`
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

final result = await BillingConnector.instance.getExpiredBillingWork(
  atMs: atMs,
);
GetExpiredBillingWorkData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
BigInt atMs = ...;

final ref = BillingConnector.instance.getExpiredBillingWork(
  atMs: atMs,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetQueuedBillingJobs
#### Required Arguments
```dart
// No required arguments
BillingConnector.instance.getQueuedBillingJobs().execute();
```

#### Optional Arguments
We return a builder for each query. For GetQueuedBillingJobs, we created `GetQueuedBillingJobsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class GetQueuedBillingJobsVariablesBuilder {
  ...

  GetQueuedBillingJobsVariablesBuilder afterCreatedAt(BigInt t) {
   _afterCreatedAt.value = t;
   return this;
  }
  GetQueuedBillingJobsVariablesBuilder afterId(String t) {
   _afterId.value = t;
   return this;
  }
  GetQueuedBillingJobsVariablesBuilder excludedTeamIds(List<String> t) {
   _excludedTeamIds.value = t;
   return this;
  }
  GetQueuedBillingJobsVariablesBuilder limit(int t) {
   _limit.value = t;
   return this;
  }

  ...
}
BillingConnector.instance.getQueuedBillingJobs()
.afterCreatedAt(afterCreatedAt)
.afterId(afterId)
.excludedTeamIds(excludedTeamIds)
.limit(limit)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<GetQueuedBillingJobsData, GetQueuedBillingJobsVariables>`
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

final result = await BillingConnector.instance.getQueuedBillingJobs();
GetQueuedBillingJobsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = BillingConnector.instance.getQueuedBillingJobs().ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingWorkerJobs
#### Required Arguments
```dart
String workerHost = ...;
BillingConnector.instance.getBillingWorkerJobs(
  workerHost: workerHost,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingWorkerJobsData, GetBillingWorkerJobsVariables>`
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

final result = await BillingConnector.instance.getBillingWorkerJobs(
  workerHost: workerHost,
);
GetBillingWorkerJobsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String workerHost = ...;

final ref = BillingConnector.instance.getBillingWorkerJobs(
  workerHost: workerHost,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingJob
#### Required Arguments
```dart
String id = ...;
BillingConnector.instance.getBillingJob(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingJobData, GetBillingJobVariables>`
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

final result = await BillingConnector.instance.getBillingJob(
  id: id,
);
GetBillingJobData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = BillingConnector.instance.getBillingJob(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingStripeState
#### Required Arguments
```dart
String teamId = ...;
bool livemode = ...;
BillingConnector.instance.getBillingStripeState(
  teamId: teamId,
  livemode: livemode,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingStripeStateData, GetBillingStripeStateVariables>`
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

final result = await BillingConnector.instance.getBillingStripeState(
  teamId: teamId,
  livemode: livemode,
);
GetBillingStripeStateData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
bool livemode = ...;

final ref = BillingConnector.instance.getBillingStripeState(
  teamId: teamId,
  livemode: livemode,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingStripeEvent
#### Required Arguments
```dart
String eventId = ...;
BillingConnector.instance.getBillingStripeEvent(
  eventId: eventId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingStripeEventData, GetBillingStripeEventVariables>`
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

final result = await BillingConnector.instance.getBillingStripeEvent(
  eventId: eventId,
);
GetBillingStripeEventData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String eventId = ...;

final ref = BillingConnector.instance.getBillingStripeEvent(
  eventId: eventId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingTrialEligibility
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
BillingConnector.instance.getBillingTrialEligibility(
  teamId: teamId,
  userId: userId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingTrialEligibilityData, GetBillingTrialEligibilityVariables>`
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

final result = await BillingConnector.instance.getBillingTrialEligibility(
  teamId: teamId,
  userId: userId,
);
GetBillingTrialEligibilityData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;

final ref = BillingConnector.instance.getBillingTrialEligibility(
  teamId: teamId,
  userId: userId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBillingPeriodUsage
#### Required Arguments
```dart
String teamId = ...;
String periodId = ...;
BigInt atMs = ...;
BillingConnector.instance.getBillingPeriodUsage(
  teamId: teamId,
  periodId: periodId,
  atMs: atMs,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBillingPeriodUsageData, GetBillingPeriodUsageVariables>`
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

final result = await BillingConnector.instance.getBillingPeriodUsage(
  teamId: teamId,
  periodId: periodId,
  atMs: atMs,
);
GetBillingPeriodUsageData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String periodId = ...;
BigInt atMs = ...;

final ref = BillingConnector.instance.getBillingPeriodUsage(
  teamId: teamId,
  periodId: periodId,
  atMs: atMs,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateBillingAdmission
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
String jobId = ...;
String workerHost = ...;
String periodId = ...;
BigInt atMs = ...;
BillingConnector.instance.createBillingAdmission(
  id: id,
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  periodId: periodId,
  atMs: atMs,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateBillingAdmission, we created `CreateBillingAdmissionBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateBillingAdmissionVariablesBuilder {
  ...
   CreateBillingAdmissionVariablesBuilder vmName(String? t) {
   _vmName.value = t;
   return this;
  }

  ...
}
BillingConnector.instance.createBillingAdmission(
  id: id,
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  periodId: periodId,
  atMs: atMs,
)
.vmName(vmName)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateBillingAdmissionData, CreateBillingAdmissionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.createBillingAdmission(
  id: id,
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  periodId: periodId,
  atMs: atMs,
);
CreateBillingAdmissionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
String jobId = ...;
String workerHost = ...;
String periodId = ...;
BigInt atMs = ...;

final ref = BillingConnector.instance.createBillingAdmission(
  id: id,
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  periodId: periodId,
  atMs: atMs,
).ref();
ref.execute();
```


### BindBillingAdmissionRun
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
String jobId = ...;
String workerHost = ...;
String runId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;
BillingConnector.instance.bindBillingAdmissionRun(
  id: id,
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<BindBillingAdmissionRunData, BindBillingAdmissionRunVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.bindBillingAdmissionRun(
  id: id,
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
);
BindBillingAdmissionRunData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
String jobId = ...;
String workerHost = ...;
String runId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;

final ref = BillingConnector.instance.bindBillingAdmissionRun(
  id: id,
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
).ref();
ref.execute();
```


### ExpireBillingAdmission
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;
BillingConnector.instance.expireBillingAdmission(
  id: id,
  teamId: teamId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
).execute();
```

#### Optional Arguments
We return a builder for each query. For ExpireBillingAdmission, we created `ExpireBillingAdmissionBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ExpireBillingAdmissionVariablesBuilder {
  ...
   ExpireBillingAdmissionVariablesBuilder runId(String? t) {
   _runId.value = t;
   return this;
  }

  ...
}
BillingConnector.instance.expireBillingAdmission(
  id: id,
  teamId: teamId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
)
.runId(runId)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<ExpireBillingAdmissionData, ExpireBillingAdmissionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.expireBillingAdmission(
  id: id,
  teamId: teamId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
);
ExpireBillingAdmissionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;

final ref = BillingConnector.instance.expireBillingAdmission(
  id: id,
  teamId: teamId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
).ref();
ref.execute();
```


### CreateBillingCheckoutCreation
#### Required Arguments
```dart
String idempotencyKey = ...;
String teamId = ...;
String userId = ...;
String planId = ...;
String stripeCustomerId = ...;
String stripePriceId = ...;
String successUrl = ...;
String cancelUrl = ...;
bool livemode = ...;
BigInt createdAt = ...;
BillingConnector.instance.createBillingCheckoutCreation(
  idempotencyKey: idempotencyKey,
  teamId: teamId,
  userId: userId,
  planId: planId,
  stripeCustomerId: stripeCustomerId,
  stripePriceId: stripePriceId,
  successUrl: successUrl,
  cancelUrl: cancelUrl,
  livemode: livemode,
  createdAt: createdAt,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateBillingCheckoutCreationData, CreateBillingCheckoutCreationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.createBillingCheckoutCreation(
  idempotencyKey: idempotencyKey,
  teamId: teamId,
  userId: userId,
  planId: planId,
  stripeCustomerId: stripeCustomerId,
  stripePriceId: stripePriceId,
  successUrl: successUrl,
  cancelUrl: cancelUrl,
  livemode: livemode,
  createdAt: createdAt,
);
CreateBillingCheckoutCreationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String idempotencyKey = ...;
String teamId = ...;
String userId = ...;
String planId = ...;
String stripeCustomerId = ...;
String stripePriceId = ...;
String successUrl = ...;
String cancelUrl = ...;
bool livemode = ...;
BigInt createdAt = ...;

final ref = BillingConnector.instance.createBillingCheckoutCreation(
  idempotencyKey: idempotencyKey,
  teamId: teamId,
  userId: userId,
  planId: planId,
  stripeCustomerId: stripeCustomerId,
  stripePriceId: stripePriceId,
  successUrl: successUrl,
  cancelUrl: cancelUrl,
  livemode: livemode,
  createdAt: createdAt,
).ref();
ref.execute();
```


### RecordBillingCheckoutSession
#### Required Arguments
```dart
String idempotencyKey = ...;
String teamId = ...;
String planId = ...;
String stripeCustomerId = ...;
String stripePriceId = ...;
String successUrl = ...;
String cancelUrl = ...;
bool livemode = ...;
BigInt createdAt = ...;
String stripeCheckoutSessionId = ...;
BillingConnector.instance.recordBillingCheckoutSession(
  idempotencyKey: idempotencyKey,
  teamId: teamId,
  planId: planId,
  stripeCustomerId: stripeCustomerId,
  stripePriceId: stripePriceId,
  successUrl: successUrl,
  cancelUrl: cancelUrl,
  livemode: livemode,
  createdAt: createdAt,
  stripeCheckoutSessionId: stripeCheckoutSessionId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<RecordBillingCheckoutSessionData, RecordBillingCheckoutSessionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.recordBillingCheckoutSession(
  idempotencyKey: idempotencyKey,
  teamId: teamId,
  planId: planId,
  stripeCustomerId: stripeCustomerId,
  stripePriceId: stripePriceId,
  successUrl: successUrl,
  cancelUrl: cancelUrl,
  livemode: livemode,
  createdAt: createdAt,
  stripeCheckoutSessionId: stripeCheckoutSessionId,
);
RecordBillingCheckoutSessionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String idempotencyKey = ...;
String teamId = ...;
String planId = ...;
String stripeCustomerId = ...;
String stripePriceId = ...;
String successUrl = ...;
String cancelUrl = ...;
bool livemode = ...;
BigInt createdAt = ...;
String stripeCheckoutSessionId = ...;

final ref = BillingConnector.instance.recordBillingCheckoutSession(
  idempotencyKey: idempotencyKey,
  teamId: teamId,
  planId: planId,
  stripeCustomerId: stripeCustomerId,
  stripePriceId: stripePriceId,
  successUrl: successUrl,
  cancelUrl: cancelUrl,
  livemode: livemode,
  createdAt: createdAt,
  stripeCheckoutSessionId: stripeCheckoutSessionId,
).ref();
ref.execute();
```


### CloseBillingCheckoutCreation
#### Required Arguments
```dart
String idempotencyKey = ...;
String teamId = ...;
String stripeCustomerId = ...;
bool livemode = ...;
String stripeCheckoutSessionId = ...;
BigInt closedAt = ...;
BillingConnector.instance.closeBillingCheckoutCreation(
  idempotencyKey: idempotencyKey,
  teamId: teamId,
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
  stripeCheckoutSessionId: stripeCheckoutSessionId,
  closedAt: closedAt,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CloseBillingCheckoutCreationData, CloseBillingCheckoutCreationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.closeBillingCheckoutCreation(
  idempotencyKey: idempotencyKey,
  teamId: teamId,
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
  stripeCheckoutSessionId: stripeCheckoutSessionId,
  closedAt: closedAt,
);
CloseBillingCheckoutCreationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String idempotencyKey = ...;
String teamId = ...;
String stripeCustomerId = ...;
bool livemode = ...;
String stripeCheckoutSessionId = ...;
BigInt closedAt = ...;

final ref = BillingConnector.instance.closeBillingCheckoutCreation(
  idempotencyKey: idempotencyKey,
  teamId: teamId,
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
  stripeCheckoutSessionId: stripeCheckoutSessionId,
  closedAt: closedAt,
).ref();
ref.execute();
```


### CreateBillingCustomerCreation
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
String idempotencyKey = ...;
bool livemode = ...;
BigInt createdAt = ...;
BillingConnector.instance.createBillingCustomerCreation(
  teamId: teamId,
  userId: userId,
  idempotencyKey: idempotencyKey,
  livemode: livemode,
  createdAt: createdAt,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateBillingCustomerCreationData, CreateBillingCustomerCreationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.createBillingCustomerCreation(
  teamId: teamId,
  userId: userId,
  idempotencyKey: idempotencyKey,
  livemode: livemode,
  createdAt: createdAt,
);
CreateBillingCustomerCreationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;
String idempotencyKey = ...;
bool livemode = ...;
BigInt createdAt = ...;

final ref = BillingConnector.instance.createBillingCustomerCreation(
  teamId: teamId,
  userId: userId,
  idempotencyKey: idempotencyKey,
  livemode: livemode,
  createdAt: createdAt,
).ref();
ref.execute();
```


### RecordBillingCustomer
#### Required Arguments
```dart
String teamId = ...;
String idempotencyKey = ...;
bool livemode = ...;
String stripeCustomerId = ...;
BillingConnector.instance.recordBillingCustomer(
  teamId: teamId,
  idempotencyKey: idempotencyKey,
  livemode: livemode,
  stripeCustomerId: stripeCustomerId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<RecordBillingCustomerData, RecordBillingCustomerVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.recordBillingCustomer(
  teamId: teamId,
  idempotencyKey: idempotencyKey,
  livemode: livemode,
  stripeCustomerId: stripeCustomerId,
);
RecordBillingCustomerData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String idempotencyKey = ...;
bool livemode = ...;
String stripeCustomerId = ...;

final ref = BillingConnector.instance.recordBillingCustomer(
  teamId: teamId,
  idempotencyKey: idempotencyKey,
  livemode: livemode,
  stripeCustomerId: stripeCustomerId,
).ref();
ref.execute();
```


### DeleteBillingTeam
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
bool livemode = ...;
BillingConnector.instance.deleteBillingTeam(
  teamId: teamId,
  userId: userId,
  livemode: livemode,
).execute();
```

#### Optional Arguments
We return a builder for each query. For DeleteBillingTeam, we created `DeleteBillingTeamBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class DeleteBillingTeamVariablesBuilder {
  ...
   DeleteBillingTeamVariablesBuilder expectedCustomerCreationKey(String? t) {
   _expectedCustomerCreationKey.value = t;
   return this;
  }
  DeleteBillingTeamVariablesBuilder expectedStripeCustomerId(String? t) {
   _expectedStripeCustomerId.value = t;
   return this;
  }
  DeleteBillingTeamVariablesBuilder expectedStripeRevision(BigInt? t) {
   _expectedStripeRevision.value = t;
   return this;
  }

  ...
}
BillingConnector.instance.deleteBillingTeam(
  teamId: teamId,
  userId: userId,
  livemode: livemode,
)
.expectedCustomerCreationKey(expectedCustomerCreationKey)
.expectedStripeCustomerId(expectedStripeCustomerId)
.expectedStripeRevision(expectedStripeRevision)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<DeleteBillingTeamData, DeleteBillingTeamVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.deleteBillingTeam(
  teamId: teamId,
  userId: userId,
  livemode: livemode,
);
DeleteBillingTeamData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;
bool livemode = ...;

final ref = BillingConnector.instance.deleteBillingTeam(
  teamId: teamId,
  userId: userId,
  livemode: livemode,
).ref();
ref.execute();
```


### CompleteBillingTeamCleanup
#### Required Arguments
```dart
String teamId = ...;
BillingConnector.instance.completeBillingTeamCleanup(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CompleteBillingTeamCleanupData, CompleteBillingTeamCleanupVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.completeBillingTeamCleanup(
  teamId: teamId,
);
CompleteBillingTeamCleanupData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = BillingConnector.instance.completeBillingTeamCleanup(
  teamId: teamId,
).ref();
ref.execute();
```


### AcknowledgeBillingCredentialCleanup
#### Required Arguments
```dart
String teamId = ...;
String path = ...;
String kind = ...;
BillingConnector.instance.acknowledgeBillingCredentialCleanup(
  teamId: teamId,
  path: path,
  kind: kind,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<AcknowledgeBillingCredentialCleanupData, AcknowledgeBillingCredentialCleanupVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.acknowledgeBillingCredentialCleanup(
  teamId: teamId,
  path: path,
  kind: kind,
);
AcknowledgeBillingCredentialCleanupData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String path = ...;
String kind = ...;

final ref = BillingConnector.instance.acknowledgeBillingCredentialCleanup(
  teamId: teamId,
  path: path,
  kind: kind,
).ref();
ref.execute();
```


### DeferBillingTeamCleanup
#### Required Arguments
```dart
String teamId = ...;
BillingConnector.instance.deferBillingTeamCleanup(
  teamId: teamId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeferBillingTeamCleanupData, DeferBillingTeamCleanupVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.deferBillingTeamCleanup(
  teamId: teamId,
);
DeferBillingTeamCleanupData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;

final ref = BillingConnector.instance.deferBillingTeamCleanup(
  teamId: teamId,
).ref();
ref.execute();
```


### StartBillingExecution
#### Required Arguments
```dart
String admissionId = ...;
String teamId = ...;
String jobId = ...;
String workerHost = ...;
String runId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;
BillingConnector.instance.startBillingExecution(
  admissionId: admissionId,
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<StartBillingExecutionData, StartBillingExecutionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.startBillingExecution(
  admissionId: admissionId,
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
);
StartBillingExecutionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String admissionId = ...;
String teamId = ...;
String jobId = ...;
String workerHost = ...;
String runId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;

final ref = BillingConnector.instance.startBillingExecution(
  admissionId: admissionId,
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
).ref();
ref.execute();
```


### HeartbeatBillingExecution
#### Required Arguments
```dart
String teamId = ...;
String jobId = ...;
String workerHost = ...;
String runId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;
BillingConnector.instance.heartbeatBillingExecution(
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<HeartbeatBillingExecutionData, HeartbeatBillingExecutionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.heartbeatBillingExecution(
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
);
HeartbeatBillingExecutionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String jobId = ...;
String workerHost = ...;
String runId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;

final ref = BillingConnector.instance.heartbeatBillingExecution(
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
).ref();
ref.execute();
```


### FinishBillingExecution
#### Required Arguments
```dart
String teamId = ...;
String jobId = ...;
String workerHost = ...;
String runId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;
String outcome = ...;
BillingConnector.instance.finishBillingExecution(
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
  outcome: outcome,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<FinishBillingExecutionData, FinishBillingExecutionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.finishBillingExecution(
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
  outcome: outcome,
);
FinishBillingExecutionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String jobId = ...;
String workerHost = ...;
String runId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;
String outcome = ...;

final ref = BillingConnector.instance.finishBillingExecution(
  teamId: teamId,
  jobId: jobId,
  workerHost: workerHost,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
  outcome: outcome,
).ref();
ref.execute();
```


### ExpireBillingExecution
#### Required Arguments
```dart
String teamId = ...;
String runId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;
BillingConnector.instance.expireBillingExecution(
  teamId: teamId,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<ExpireBillingExecutionData, ExpireBillingExecutionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.expireBillingExecution(
  teamId: teamId,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
);
ExpireBillingExecutionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String runId = ...;
BigInt expectedUsageRevision = ...;
BigInt atMs = ...;

final ref = BillingConnector.instance.expireBillingExecution(
  teamId: teamId,
  runId: runId,
  expectedUsageRevision: expectedUsageRevision,
  atMs: atMs,
).ref();
ref.execute();
```


### CreateBillingPeriod
#### Required Arguments
```dart
String id = ...;
String teamId = ...;
String planId = ...;
String periodType = ...;
BigInt startsAt = ...;
BigInt endsAt = ...;
BillingConnector.instance.createBillingPeriod(
  id: id,
  teamId: teamId,
  planId: planId,
  periodType: periodType,
  startsAt: startsAt,
  endsAt: endsAt,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateBillingPeriod, we created `CreateBillingPeriodBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateBillingPeriodVariablesBuilder {
  ...
   CreateBillingPeriodVariablesBuilder allowanceSeconds(BigInt? t) {
   _allowanceSeconds.value = t;
   return this;
  }

  ...
}
BillingConnector.instance.createBillingPeriod(
  id: id,
  teamId: teamId,
  planId: planId,
  periodType: periodType,
  startsAt: startsAt,
  endsAt: endsAt,
)
.allowanceSeconds(allowanceSeconds)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateBillingPeriodData, CreateBillingPeriodVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.createBillingPeriod(
  id: id,
  teamId: teamId,
  planId: planId,
  periodType: periodType,
  startsAt: startsAt,
  endsAt: endsAt,
);
CreateBillingPeriodData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String teamId = ...;
String planId = ...;
String periodType = ...;
BigInt startsAt = ...;
BigInt endsAt = ...;

final ref = BillingConnector.instance.createBillingPeriod(
  id: id,
  teamId: teamId,
  planId: planId,
  periodType: periodType,
  startsAt: startsAt,
  endsAt: endsAt,
).ref();
ref.execute();
```


### InitializeBillingStripeState
#### Required Arguments
```dart
String teamId = ...;
String stripeCustomerId = ...;
bool livemode = ...;
BillingConnector.instance.initializeBillingStripeState(
  teamId: teamId,
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<InitializeBillingStripeStateData, InitializeBillingStripeStateVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.initializeBillingStripeState(
  teamId: teamId,
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
);
InitializeBillingStripeStateData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String stripeCustomerId = ...;
bool livemode = ...;

final ref = BillingConnector.instance.initializeBillingStripeState(
  teamId: teamId,
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
).ref();
ref.execute();
```


### RecordBillingStripeEvent
#### Required Arguments
```dart
String teamId = ...;
String stripeCustomerId = ...;
bool livemode = ...;
BigInt expectedRevision = ...;
String subscriptionStatus = ...;
bool cancelAtPeriodEnd = ...;
String eventId = ...;
String eventType = ...;
BigInt eventCreated = ...;
BigInt processedAt = ...;
BillingConnector.instance.recordBillingStripeEvent(
  teamId: teamId,
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
  expectedRevision: expectedRevision,
  subscriptionStatus: subscriptionStatus,
  cancelAtPeriodEnd: cancelAtPeriodEnd,
  eventId: eventId,
  eventType: eventType,
  eventCreated: eventCreated,
  processedAt: processedAt,
).execute();
```

#### Optional Arguments
We return a builder for each query. For RecordBillingStripeEvent, we created `RecordBillingStripeEventBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class RecordBillingStripeEventVariablesBuilder {
  ...
   RecordBillingStripeEventVariablesBuilder stripeSubscriptionId(String? t) {
   _stripeSubscriptionId.value = t;
   return this;
  }
  RecordBillingStripeEventVariablesBuilder planId(String? t) {
   _planId.value = t;
   return this;
  }
  RecordBillingStripeEventVariablesBuilder paidPeriodId(String? t) {
   _paidPeriodId.value = t;
   return this;
  }

  ...
}
BillingConnector.instance.recordBillingStripeEvent(
  teamId: teamId,
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
  expectedRevision: expectedRevision,
  subscriptionStatus: subscriptionStatus,
  cancelAtPeriodEnd: cancelAtPeriodEnd,
  eventId: eventId,
  eventType: eventType,
  eventCreated: eventCreated,
  processedAt: processedAt,
)
.stripeSubscriptionId(stripeSubscriptionId)
.planId(planId)
.paidPeriodId(paidPeriodId)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<RecordBillingStripeEventData, RecordBillingStripeEventVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.recordBillingStripeEvent(
  teamId: teamId,
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
  expectedRevision: expectedRevision,
  subscriptionStatus: subscriptionStatus,
  cancelAtPeriodEnd: cancelAtPeriodEnd,
  eventId: eventId,
  eventType: eventType,
  eventCreated: eventCreated,
  processedAt: processedAt,
);
RecordBillingStripeEventData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String stripeCustomerId = ...;
bool livemode = ...;
BigInt expectedRevision = ...;
String subscriptionStatus = ...;
bool cancelAtPeriodEnd = ...;
String eventId = ...;
String eventType = ...;
BigInt eventCreated = ...;
BigInt processedAt = ...;

final ref = BillingConnector.instance.recordBillingStripeEvent(
  teamId: teamId,
  stripeCustomerId: stripeCustomerId,
  livemode: livemode,
  expectedRevision: expectedRevision,
  subscriptionStatus: subscriptionStatus,
  cancelAtPeriodEnd: cancelAtPeriodEnd,
  eventId: eventId,
  eventType: eventType,
  eventCreated: eventCreated,
  processedAt: processedAt,
).ref();
ref.execute();
```


### StartBillingTrial
#### Required Arguments
```dart
String teamId = ...;
String userId = ...;
String periodId = ...;
BillingConnector.instance.startBillingTrial(
  teamId: teamId,
  userId: userId,
  periodId: periodId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For StartBillingTrial, we created `StartBillingTrialBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class StartBillingTrialVariablesBuilder {
  ...
   StartBillingTrialVariablesBuilder allowanceSeconds(BigInt? t) {
   _allowanceSeconds.value = t;
   return this;
  }

  ...
}
BillingConnector.instance.startBillingTrial(
  teamId: teamId,
  userId: userId,
  periodId: periodId,
)
.allowanceSeconds(allowanceSeconds)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<StartBillingTrialData, StartBillingTrialVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await BillingConnector.instance.startBillingTrial(
  teamId: teamId,
  userId: userId,
  periodId: periodId,
);
StartBillingTrialData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String teamId = ...;
String userId = ...;
String periodId = ...;

final ref = BillingConnector.instance.startBillingTrial(
  teamId: teamId,
  userId: userId,
  periodId: periodId,
).ref();
ref.execute();
```
