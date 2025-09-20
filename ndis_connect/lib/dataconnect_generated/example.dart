library;
import 'dart:convert';

import 'package:firebase_data_connect/firebase_data_connect.dart';

part 'create_new_service_request.dart';
part 'list_all_users.dart';
part 'list_support_workers_with_police_check.dart';
part 'update_user_email.dart';







class ExampleConnector {
  
  
  ListAllUsersVariablesBuilder listAllUsers () {
    return ListAllUsersVariablesBuilder(dataConnect, );
  }
  
  
  CreateNewServiceRequestVariablesBuilder createNewServiceRequest ({required String participantProfileId, required String serviceId, required String startTime, required String endTime, required DateTime requestedDate, required String status, }) {
    return CreateNewServiceRequestVariablesBuilder(dataConnect, participantProfileId: participantProfileId,serviceId: serviceId,startTime: startTime,endTime: endTime,requestedDate: requestedDate,status: status,);
  }
  
  
  ListSupportWorkersWithPoliceCheckVariablesBuilder listSupportWorkersWithPoliceCheck () {
    return ListSupportWorkersWithPoliceCheckVariablesBuilder(dataConnect, );
  }
  
  
  UpdateUserEmailVariablesBuilder updateUserEmail ({required String id, required String email, }) {
    return UpdateUserEmailVariablesBuilder(dataConnect, id: id,email: email,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'ndis2',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}

