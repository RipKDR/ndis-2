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
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### ListAllUsers
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listAllUsers().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListAllUsersData, void>`
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

final result = await ExampleConnector.instance.listAllUsers();
ListAllUsersData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listAllUsers().ref();
ref.execute();

ref.subscribe(...);
```


### ListSupportWorkersWithPoliceCheck
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listSupportWorkersWithPoliceCheck().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListSupportWorkersWithPoliceCheckData, void>`
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

final result = await ExampleConnector.instance.listSupportWorkersWithPoliceCheck();
ListSupportWorkersWithPoliceCheckData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listSupportWorkersWithPoliceCheck().ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateNewServiceRequest
#### Required Arguments
```dart
String participantProfileId = ...;
String serviceId = ...;
String startTime = ...;
String endTime = ...;
DateTime requestedDate = ...;
String status = ...;
ExampleConnector.instance.createNewServiceRequest(
  participantProfileId: participantProfileId,
  serviceId: serviceId,
  startTime: startTime,
  endTime: endTime,
  requestedDate: requestedDate,
  status: status,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateNewServiceRequestData, CreateNewServiceRequestVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createNewServiceRequest(
  participantProfileId: participantProfileId,
  serviceId: serviceId,
  startTime: startTime,
  endTime: endTime,
  requestedDate: requestedDate,
  status: status,
);
CreateNewServiceRequestData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String participantProfileId = ...;
String serviceId = ...;
String startTime = ...;
String endTime = ...;
DateTime requestedDate = ...;
String status = ...;

final ref = ExampleConnector.instance.createNewServiceRequest(
  participantProfileId: participantProfileId,
  serviceId: serviceId,
  startTime: startTime,
  endTime: endTime,
  requestedDate: requestedDate,
  status: status,
).ref();
ref.execute();
```


### UpdateUserEmail
#### Required Arguments
```dart
String id = ...;
String email = ...;
ExampleConnector.instance.updateUserEmail(
  id: id,
  email: email,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateUserEmailData, UpdateUserEmailVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateUserEmail(
  id: id,
  email: email,
);
UpdateUserEmailData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String email = ...;

final ref = ExampleConnector.instance.updateUserEmail(
  id: id,
  email: email,
).ref();
ref.execute();
```

