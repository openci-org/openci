// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_development_connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocalDevelopmentConnection {

 ConnectionProfile get profile; String get apiUrl; String get emulatorHost; int get emulatorPort;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalDevelopmentConnection&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.apiUrl, apiUrl) || other.apiUrl == apiUrl)&&(identical(other.emulatorHost, emulatorHost) || other.emulatorHost == emulatorHost)&&(identical(other.emulatorPort, emulatorPort) || other.emulatorPort == emulatorPort));
}


@override
int get hashCode => Object.hash(runtimeType,profile,apiUrl,emulatorHost,emulatorPort);

@override
String toString() {
  return 'LocalDevelopmentConnection(profile: $profile, apiUrl: $apiUrl, emulatorHost: $emulatorHost, emulatorPort: $emulatorPort)';
}


}





/// @nodoc


class _LocalDevelopmentConnection extends LocalDevelopmentConnection {
   _LocalDevelopmentConnection({required this.apiUrl, required this.emulatorHost, required this.emulatorPort}): super._();


@override final  String apiUrl;
@override final  String emulatorHost;
@override final  int emulatorPort;




@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalDevelopmentConnection&&(identical(other.apiUrl, apiUrl) || other.apiUrl == apiUrl)&&(identical(other.emulatorHost, emulatorHost) || other.emulatorHost == emulatorHost)&&(identical(other.emulatorPort, emulatorPort) || other.emulatorPort == emulatorPort));
}


@override
int get hashCode => Object.hash(runtimeType,apiUrl,emulatorHost,emulatorPort);

@override
String toString() {
  return 'LocalDevelopmentConnection._validated(apiUrl: $apiUrl, emulatorHost: $emulatorHost, emulatorPort: $emulatorPort)';
}


}




// dart format on
