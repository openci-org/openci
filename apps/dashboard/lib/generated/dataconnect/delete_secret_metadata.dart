part of 'default.dart';

class DeleteSecretMetadataVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteSecretMetadataVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteSecretMetadataData> dataDeserializer = (dynamic json)  => DeleteSecretMetadataData.fromJson(jsonDecode(json));
  Serializer<DeleteSecretMetadataVariables> varsSerializer = (DeleteSecretMetadataVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteSecretMetadataData, DeleteSecretMetadataVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteSecretMetadataData, DeleteSecretMetadataVariables> ref() {
    DeleteSecretMetadataVariables vars= DeleteSecretMetadataVariables(id: id,);
    return _dataConnect.mutation("DeleteSecretMetadata", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteSecretMetadataSecretDelete {
  final String id;
  DeleteSecretMetadataSecretDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSecretMetadataSecretDelete otherTyped = other as DeleteSecretMetadataSecretDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSecretMetadataSecretDelete({
    required this.id,
  });
}

@immutable
class DeleteSecretMetadataData {
  final DeleteSecretMetadataSecretDelete? secret_delete;
  DeleteSecretMetadataData.fromJson(dynamic json):
  
  secret_delete = json['secret_delete'] == null ? null : DeleteSecretMetadataSecretDelete.fromJson(json['secret_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSecretMetadataData otherTyped = other as DeleteSecretMetadataData;
    return secret_delete == otherTyped.secret_delete;
    
  }
  @override
  int get hashCode => secret_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (secret_delete != null) {
      json['secret_delete'] = secret_delete!.toJson();
    }
    return json;
  }

  DeleteSecretMetadataData({
    this.secret_delete,
  });
}

@immutable
class DeleteSecretMetadataVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteSecretMetadataVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSecretMetadataVariables otherTyped = other as DeleteSecretMetadataVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSecretMetadataVariables({
    required this.id,
  });
}

