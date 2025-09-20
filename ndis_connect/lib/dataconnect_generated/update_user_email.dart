part of 'example.dart';

class UpdateUserEmailVariablesBuilder {
  String id;
  String email;

  final FirebaseDataConnect _dataConnect;
  UpdateUserEmailVariablesBuilder(this._dataConnect, {required  this.id,required  this.email,});
  Deserializer<UpdateUserEmailData> dataDeserializer = (dynamic json)  => UpdateUserEmailData.fromJson(jsonDecode(json));
  Serializer<UpdateUserEmailVariables> varsSerializer = (UpdateUserEmailVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateUserEmailData, UpdateUserEmailVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateUserEmailData, UpdateUserEmailVariables> ref() {
    UpdateUserEmailVariables vars= UpdateUserEmailVariables(id: id,email: email,);
    return _dataConnect.mutation("UpdateUserEmail", dataDeserializer, varsSerializer, vars);
  }
}

class UpdateUserEmailUserUpdate {
  String id;
  UpdateUserEmailUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateUserEmailUserUpdate({
    required this.id,
  });
}

class UpdateUserEmailData {
  UpdateUserEmailUserUpdate? user_update;
  UpdateUserEmailData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateUserEmailUserUpdate.fromJson(json['user_update']);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateUserEmailData({
    this.user_update,
  });
}

class UpdateUserEmailVariables {
  String id;
  String email;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateUserEmailVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  email = nativeFromJson<String>(json['email']);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['email'] = nativeToJson<String>(email);
    return json;
  }

  UpdateUserEmailVariables({
    required this.id,
    required this.email,
  });
}

