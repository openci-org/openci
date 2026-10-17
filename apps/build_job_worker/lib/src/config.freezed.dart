// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Config {

 String get serverUrl; String get internalApiKey; String get orchardServiceAccountName; String get orchardServiceAccountToken; String get baseVmName; String get orchardApiUrl; String get lokiUrl; String get internalLokiUrl; String? get sentryDsn;
/// Create a copy of Config
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConfigCopyWith<Config> get copyWith => _$ConfigCopyWithImpl<Config>(this as Config, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Config&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.internalApiKey, internalApiKey) || other.internalApiKey == internalApiKey)&&(identical(other.orchardServiceAccountName, orchardServiceAccountName) || other.orchardServiceAccountName == orchardServiceAccountName)&&(identical(other.orchardServiceAccountToken, orchardServiceAccountToken) || other.orchardServiceAccountToken == orchardServiceAccountToken)&&(identical(other.baseVmName, baseVmName) || other.baseVmName == baseVmName)&&(identical(other.orchardApiUrl, orchardApiUrl) || other.orchardApiUrl == orchardApiUrl)&&(identical(other.lokiUrl, lokiUrl) || other.lokiUrl == lokiUrl)&&(identical(other.internalLokiUrl, internalLokiUrl) || other.internalLokiUrl == internalLokiUrl)&&(identical(other.sentryDsn, sentryDsn) || other.sentryDsn == sentryDsn));
}


@override
int get hashCode => Object.hash(runtimeType,serverUrl,internalApiKey,orchardServiceAccountName,orchardServiceAccountToken,baseVmName,orchardApiUrl,lokiUrl,internalLokiUrl,sentryDsn);



}

/// @nodoc
abstract mixin class $ConfigCopyWith<$Res>  {
  factory $ConfigCopyWith(Config value, $Res Function(Config) _then) = _$ConfigCopyWithImpl;
@useResult
$Res call({
 String serverUrl, String internalApiKey, String orchardServiceAccountName, String orchardServiceAccountToken, String baseVmName, String orchardApiUrl, String lokiUrl, String internalLokiUrl, String? sentryDsn
});




}
/// @nodoc
class _$ConfigCopyWithImpl<$Res>
    implements $ConfigCopyWith<$Res> {
  _$ConfigCopyWithImpl(this._self, this._then);

  final Config _self;
  final $Res Function(Config) _then;

/// Create a copy of Config
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverUrl = null,Object? internalApiKey = null,Object? orchardServiceAccountName = null,Object? orchardServiceAccountToken = null,Object? baseVmName = null,Object? orchardApiUrl = null,Object? lokiUrl = null,Object? internalLokiUrl = null,Object? sentryDsn = freezed,}) {
  return _then(_self.copyWith(
serverUrl: null == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String,internalApiKey: null == internalApiKey ? _self.internalApiKey : internalApiKey // ignore: cast_nullable_to_non_nullable
as String,orchardServiceAccountName: null == orchardServiceAccountName ? _self.orchardServiceAccountName : orchardServiceAccountName // ignore: cast_nullable_to_non_nullable
as String,orchardServiceAccountToken: null == orchardServiceAccountToken ? _self.orchardServiceAccountToken : orchardServiceAccountToken // ignore: cast_nullable_to_non_nullable
as String,baseVmName: null == baseVmName ? _self.baseVmName : baseVmName // ignore: cast_nullable_to_non_nullable
as String,orchardApiUrl: null == orchardApiUrl ? _self.orchardApiUrl : orchardApiUrl // ignore: cast_nullable_to_non_nullable
as String,lokiUrl: null == lokiUrl ? _self.lokiUrl : lokiUrl // ignore: cast_nullable_to_non_nullable
as String,internalLokiUrl: null == internalLokiUrl ? _self.internalLokiUrl : internalLokiUrl // ignore: cast_nullable_to_non_nullable
as String,sentryDsn: freezed == sentryDsn ? _self.sentryDsn : sentryDsn // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Config].
extension ConfigPatterns on Config {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Config value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Config() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Config value)  $default,){
final _that = this;
switch (_that) {
case _Config():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Config value)?  $default,){
final _that = this;
switch (_that) {
case _Config() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serverUrl,  String internalApiKey,  String orchardServiceAccountName,  String orchardServiceAccountToken,  String baseVmName,  String orchardApiUrl,  String lokiUrl,  String internalLokiUrl,  String? sentryDsn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Config() when $default != null:
return $default(_that.serverUrl,_that.internalApiKey,_that.orchardServiceAccountName,_that.orchardServiceAccountToken,_that.baseVmName,_that.orchardApiUrl,_that.lokiUrl,_that.internalLokiUrl,_that.sentryDsn);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serverUrl,  String internalApiKey,  String orchardServiceAccountName,  String orchardServiceAccountToken,  String baseVmName,  String orchardApiUrl,  String lokiUrl,  String internalLokiUrl,  String? sentryDsn)  $default,) {final _that = this;
switch (_that) {
case _Config():
return $default(_that.serverUrl,_that.internalApiKey,_that.orchardServiceAccountName,_that.orchardServiceAccountToken,_that.baseVmName,_that.orchardApiUrl,_that.lokiUrl,_that.internalLokiUrl,_that.sentryDsn);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serverUrl,  String internalApiKey,  String orchardServiceAccountName,  String orchardServiceAccountToken,  String baseVmName,  String orchardApiUrl,  String lokiUrl,  String internalLokiUrl,  String? sentryDsn)?  $default,) {final _that = this;
switch (_that) {
case _Config() when $default != null:
return $default(_that.serverUrl,_that.internalApiKey,_that.orchardServiceAccountName,_that.orchardServiceAccountToken,_that.baseVmName,_that.orchardApiUrl,_that.lokiUrl,_that.internalLokiUrl,_that.sentryDsn);case _:
  return null;

}
}

}

/// @nodoc


class _Config implements Config {
  const _Config({required this.serverUrl, required this.internalApiKey, required this.orchardServiceAccountName, required this.orchardServiceAccountToken, this.baseVmName = 'base-macos', this.orchardApiUrl = 'https://orchard-controller:6120', this.lokiUrl = 'http://192.168.64.1:3100', this.internalLokiUrl = 'http://loki:3100', this.sentryDsn});


@override final  String serverUrl;
@override final  String internalApiKey;
@override final  String orchardServiceAccountName;
@override final  String orchardServiceAccountToken;
@override@JsonKey() final  String baseVmName;
@override@JsonKey() final  String orchardApiUrl;
@override@JsonKey() final  String lokiUrl;
@override@JsonKey() final  String internalLokiUrl;
@override final  String? sentryDsn;

/// Create a copy of Config
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfigCopyWith<_Config> get copyWith => __$ConfigCopyWithImpl<_Config>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Config&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.internalApiKey, internalApiKey) || other.internalApiKey == internalApiKey)&&(identical(other.orchardServiceAccountName, orchardServiceAccountName) || other.orchardServiceAccountName == orchardServiceAccountName)&&(identical(other.orchardServiceAccountToken, orchardServiceAccountToken) || other.orchardServiceAccountToken == orchardServiceAccountToken)&&(identical(other.baseVmName, baseVmName) || other.baseVmName == baseVmName)&&(identical(other.orchardApiUrl, orchardApiUrl) || other.orchardApiUrl == orchardApiUrl)&&(identical(other.lokiUrl, lokiUrl) || other.lokiUrl == lokiUrl)&&(identical(other.internalLokiUrl, internalLokiUrl) || other.internalLokiUrl == internalLokiUrl)&&(identical(other.sentryDsn, sentryDsn) || other.sentryDsn == sentryDsn));
}


@override
int get hashCode => Object.hash(runtimeType,serverUrl,internalApiKey,orchardServiceAccountName,orchardServiceAccountToken,baseVmName,orchardApiUrl,lokiUrl,internalLokiUrl,sentryDsn);



}

/// @nodoc
abstract mixin class _$ConfigCopyWith<$Res> implements $ConfigCopyWith<$Res> {
  factory _$ConfigCopyWith(_Config value, $Res Function(_Config) _then) = __$ConfigCopyWithImpl;
@override @useResult
$Res call({
 String serverUrl, String internalApiKey, String orchardServiceAccountName, String orchardServiceAccountToken, String baseVmName, String orchardApiUrl, String lokiUrl, String internalLokiUrl, String? sentryDsn
});




}
/// @nodoc
class __$ConfigCopyWithImpl<$Res>
    implements _$ConfigCopyWith<$Res> {
  __$ConfigCopyWithImpl(this._self, this._then);

  final _Config _self;
  final $Res Function(_Config) _then;

/// Create a copy of Config
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverUrl = null,Object? internalApiKey = null,Object? orchardServiceAccountName = null,Object? orchardServiceAccountToken = null,Object? baseVmName = null,Object? orchardApiUrl = null,Object? lokiUrl = null,Object? internalLokiUrl = null,Object? sentryDsn = freezed,}) {
  return _then(_Config(
serverUrl: null == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String,internalApiKey: null == internalApiKey ? _self.internalApiKey : internalApiKey // ignore: cast_nullable_to_non_nullable
as String,orchardServiceAccountName: null == orchardServiceAccountName ? _self.orchardServiceAccountName : orchardServiceAccountName // ignore: cast_nullable_to_non_nullable
as String,orchardServiceAccountToken: null == orchardServiceAccountToken ? _self.orchardServiceAccountToken : orchardServiceAccountToken // ignore: cast_nullable_to_non_nullable
as String,baseVmName: null == baseVmName ? _self.baseVmName : baseVmName // ignore: cast_nullable_to_non_nullable
as String,orchardApiUrl: null == orchardApiUrl ? _self.orchardApiUrl : orchardApiUrl // ignore: cast_nullable_to_non_nullable
as String,lokiUrl: null == lokiUrl ? _self.lokiUrl : lokiUrl // ignore: cast_nullable_to_non_nullable
as String,internalLokiUrl: null == internalLokiUrl ? _self.internalLokiUrl : internalLokiUrl // ignore: cast_nullable_to_non_nullable
as String,sentryDsn: freezed == sentryDsn ? _self.sentryDsn : sentryDsn // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
