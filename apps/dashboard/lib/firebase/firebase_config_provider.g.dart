// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_config_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SelfHostedConfig _$SelfHostedConfigFromJson(Map<String, dynamic> json) =>
    _SelfHostedConfig(
      apiKey: json['apiKey'] as String,
      appId: json['appId'] as String,
      messagingSenderId: json['messagingSenderId'] as String? ?? '',
      projectId: json['projectId'] as String,
      storageBucket: json['storageBucket'] as String? ?? '',
      dataConnectServiceId: json['dataConnectServiceId'] as String? ?? '',
    );

Map<String, dynamic> _$SelfHostedConfigToJson(_SelfHostedConfig instance) =>
    <String, dynamic>{
      'apiKey': instance.apiKey,
      'appId': instance.appId,
      'messagingSenderId': instance.messagingSenderId,
      'projectId': instance.projectId,
      'storageBucket': instance.storageBucket,
      'dataConnectServiceId': instance.dataConnectServiceId,
    };
