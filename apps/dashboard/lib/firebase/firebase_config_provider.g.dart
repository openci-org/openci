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
      authDomain: json['authDomain'] as String?,
      iosBundleId: json['iosBundleId'] as String?,
      iosClientId: json['iosClientId'] as String?,
      androidClientId: json['androidClientId'] as String?,
      databaseURL: json['databaseURL'] as String?,
      measurementId: json['measurementId'] as String?,
    );

Map<String, dynamic> _$SelfHostedConfigToJson(_SelfHostedConfig instance) =>
    <String, dynamic>{
      'apiKey': instance.apiKey,
      'appId': instance.appId,
      'messagingSenderId': instance.messagingSenderId,
      'projectId': instance.projectId,
      'storageBucket': instance.storageBucket,
      'authDomain': instance.authDomain,
      'iosBundleId': instance.iosBundleId,
      'iosClientId': instance.iosClientId,
      'androidClientId': instance.androidClientId,
      'databaseURL': instance.databaseURL,
      'measurementId': instance.measurementId,
    };
