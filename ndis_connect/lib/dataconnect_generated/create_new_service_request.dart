part of 'example.dart';

class CreateNewServiceRequestVariablesBuilder {
  String participantProfileId;
  String serviceId;
  String startTime;
  String endTime;
  DateTime requestedDate;
  String status;

  final FirebaseDataConnect _dataConnect;
  CreateNewServiceRequestVariablesBuilder(this._dataConnect, {required  this.participantProfileId,required  this.serviceId,required  this.startTime,required  this.endTime,required  this.requestedDate,required  this.status,});
  Deserializer<CreateNewServiceRequestData> dataDeserializer = (dynamic json)  => CreateNewServiceRequestData.fromJson(jsonDecode(json));
  Serializer<CreateNewServiceRequestVariables> varsSerializer = (CreateNewServiceRequestVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateNewServiceRequestData, CreateNewServiceRequestVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateNewServiceRequestData, CreateNewServiceRequestVariables> ref() {
    CreateNewServiceRequestVariables vars= CreateNewServiceRequestVariables(participantProfileId: participantProfileId,serviceId: serviceId,startTime: startTime,endTime: endTime,requestedDate: requestedDate,status: status,);
    return _dataConnect.mutation("CreateNewServiceRequest", dataDeserializer, varsSerializer, vars);
  }
}

class CreateNewServiceRequestServiceRequestInsert {
  String id;
  CreateNewServiceRequestServiceRequestInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateNewServiceRequestServiceRequestInsert({
    required this.id,
  });
}

class CreateNewServiceRequestData {
  CreateNewServiceRequestServiceRequestInsert serviceRequest_insert;
  CreateNewServiceRequestData.fromJson(dynamic json):
  
  serviceRequest_insert = CreateNewServiceRequestServiceRequestInsert.fromJson(json['serviceRequest_insert']);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['serviceRequest_insert'] = serviceRequest_insert.toJson();
    return json;
  }

  CreateNewServiceRequestData({
    required this.serviceRequest_insert,
  });
}

class CreateNewServiceRequestVariables {
  String participantProfileId;
  String serviceId;
  String startTime;
  String endTime;
  DateTime requestedDate;
  String status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateNewServiceRequestVariables.fromJson(Map<String, dynamic> json):
  
  participantProfileId = nativeFromJson<String>(json['participantProfileId']),
  serviceId = nativeFromJson<String>(json['serviceId']),
  startTime = nativeFromJson<String>(json['startTime']),
  endTime = nativeFromJson<String>(json['endTime']),
  requestedDate = nativeFromJson<DateTime>(json['requestedDate']),
  status = nativeFromJson<String>(json['status']);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['participantProfileId'] = nativeToJson<String>(participantProfileId);
    json['serviceId'] = nativeToJson<String>(serviceId);
    json['startTime'] = nativeToJson<String>(startTime);
    json['endTime'] = nativeToJson<String>(endTime);
    json['requestedDate'] = nativeToJson<DateTime>(requestedDate);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  CreateNewServiceRequestVariables({
    required this.participantProfileId,
    required this.serviceId,
    required this.startTime,
    required this.endTime,
    required this.requestedDate,
    required this.status,
  });
}

