part of 'example.dart';

class ListSupportWorkersWithPoliceCheckVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListSupportWorkersWithPoliceCheckVariablesBuilder(this._dataConnect, );
  Deserializer<ListSupportWorkersWithPoliceCheckData> dataDeserializer = (dynamic json)  => ListSupportWorkersWithPoliceCheckData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListSupportWorkersWithPoliceCheckData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListSupportWorkersWithPoliceCheckData, void> ref() {
    
    return _dataConnect.query("ListSupportWorkersWithPoliceCheck", dataDeserializer, emptySerializer, null);
  }
}

class ListSupportWorkersWithPoliceCheckSupportWorkerProfiles {
  String id;
  ListSupportWorkersWithPoliceCheckSupportWorkerProfilesUser user;
  String qualifications;
  String servicesOffered;
  ListSupportWorkersWithPoliceCheckSupportWorkerProfiles.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  user = ListSupportWorkersWithPoliceCheckSupportWorkerProfilesUser.fromJson(json['user']),
  qualifications = nativeFromJson<String>(json['qualifications']),
  servicesOffered = nativeFromJson<String>(json['servicesOffered']);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['user'] = user.toJson();
    json['qualifications'] = nativeToJson<String>(qualifications);
    json['servicesOffered'] = nativeToJson<String>(servicesOffered);
    return json;
  }

  ListSupportWorkersWithPoliceCheckSupportWorkerProfiles({
    required this.id,
    required this.user,
    required this.qualifications,
    required this.servicesOffered,
  });
}

class ListSupportWorkersWithPoliceCheckSupportWorkerProfilesUser {
  String? firstName;
  String? lastName;
  ListSupportWorkersWithPoliceCheckSupportWorkerProfilesUser.fromJson(dynamic json):
  
  firstName = json['firstName'] == null ? null : nativeFromJson<String>(json['firstName']),
  lastName = json['lastName'] == null ? null : nativeFromJson<String>(json['lastName']);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (firstName != null) {
      json['firstName'] = nativeToJson<String?>(firstName);
    }
    if (lastName != null) {
      json['lastName'] = nativeToJson<String?>(lastName);
    }
    return json;
  }

  ListSupportWorkersWithPoliceCheckSupportWorkerProfilesUser({
    this.firstName,
    this.lastName,
  });
}

class ListSupportWorkersWithPoliceCheckData {
  List<ListSupportWorkersWithPoliceCheckSupportWorkerProfiles> supportWorkerProfiles;
  ListSupportWorkersWithPoliceCheckData.fromJson(dynamic json):
  
  supportWorkerProfiles = (json['supportWorkerProfiles'] as List<dynamic>)
        .map((e) => ListSupportWorkersWithPoliceCheckSupportWorkerProfiles.fromJson(e))
        .toList();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['supportWorkerProfiles'] = supportWorkerProfiles.map((e) => e.toJson()).toList();
    return json;
  }

  ListSupportWorkersWithPoliceCheckData({
    required this.supportWorkerProfiles,
  });
}

