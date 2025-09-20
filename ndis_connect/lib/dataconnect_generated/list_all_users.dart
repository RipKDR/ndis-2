part of 'example.dart';

class ListAllUsersVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListAllUsersVariablesBuilder(this._dataConnect, );
  Deserializer<ListAllUsersData> dataDeserializer = (dynamic json)  => ListAllUsersData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListAllUsersData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListAllUsersData, void> ref() {
    
    return _dataConnect.query("ListAllUsers", dataDeserializer, emptySerializer, null);
  }
}

class ListAllUsersUsers {
  String id;
  String? firstName;
  String? lastName;
  String email;
  ListAllUsersUsers.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  firstName = json['firstName'] == null ? null : nativeFromJson<String>(json['firstName']),
  lastName = json['lastName'] == null ? null : nativeFromJson<String>(json['lastName']),
  email = nativeFromJson<String>(json['email']);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (firstName != null) {
      json['firstName'] = nativeToJson<String?>(firstName);
    }
    if (lastName != null) {
      json['lastName'] = nativeToJson<String?>(lastName);
    }
    json['email'] = nativeToJson<String>(email);
    return json;
  }

  ListAllUsersUsers({
    required this.id,
    this.firstName,
    this.lastName,
    required this.email,
  });
}

class ListAllUsersData {
  List<ListAllUsersUsers> users;
  ListAllUsersData.fromJson(dynamic json):
  
  users = (json['users'] as List<dynamic>)
        .map((e) => ListAllUsersUsers.fromJson(e))
        .toList();

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllUsersData({
    required this.users,
  });
}

