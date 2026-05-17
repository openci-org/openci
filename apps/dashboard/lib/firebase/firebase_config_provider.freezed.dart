// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'firebase_config_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SelfHostedConfig {

 String get apiKey; String get appId; String get messagingSenderId; String get projectId; String get storageBucket;
/// Create a copy of SelfHostedConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelfHostedConfigCopyWith<SelfHostedConfig> get copyWith => _$SelfHostedConfigCopyWithImpl<SelfHostedConfig>(this as SelfHostedConfig, _$identity);

  /// Serializes this SelfHostedConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelfHostedConfig&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.messagingSenderId, messagingSenderId) || other.messagingSenderId == messagingSenderId)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.storageBucket, storageBucket) || other.storageBucket == storageBucket));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,apiKey,appId,messagingSenderId,projectId,storageBucket);

@override
String toString() {
  return 'SelfHostedConfig(apiKey: $apiKey, appId: $appId, messagingSenderId: $messagingSenderId, projectId: $projectId, storageBucket: $storageBucket)';
}


}

/// @nodoc
abstract mixin class $SelfHostedConfigCopyWith<$Res>  {
  factory $SelfHostedConfigCopyWith(SelfHostedConfig value, $Res Function(SelfHostedConfig) _then) = _$SelfHostedConfigCopyWithImpl;
@useResult
$Res call({
 String apiKey, String appId, String messagingSenderId, String projectId, String storageBucket
});




}
/// @nodoc
class _$SelfHostedConfigCopyWithImpl<$Res>
    implements $SelfHostedConfigCopyWith<$Res> {
  _$SelfHostedConfigCopyWithImpl(this._self, this._then);

  final SelfHostedConfig _self;
  final $Res Function(SelfHostedConfig) _then;

/// Create a copy of SelfHostedConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? apiKey = null,Object? appId = null,Object? messagingSenderId = null,Object? projectId = null,Object? storageBucket = null,}) {
  return _then(_self.copyWith(
apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,messagingSenderId: null == messagingSenderId ? _self.messagingSenderId : messagingSenderId // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,storageBucket: null == storageBucket ? _self.storageBucket : storageBucket // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SelfHostedConfig].
extension SelfHostedConfigPatterns on SelfHostedConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SelfHostedConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SelfHostedConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SelfHostedConfig value)  $default,){
final _that = this;
switch (_that) {
case _SelfHostedConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SelfHostedConfig value)?  $default,){
final _that = this;
switch (_that) {
case _SelfHostedConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String apiKey,  String appId,  String messagingSenderId,  String projectId,  String storageBucket)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SelfHostedConfig() when $default != null:
return $default(_that.apiKey,_that.appId,_that.messagingSenderId,_that.projectId,_that.storageBucket);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String apiKey,  String appId,  String messagingSenderId,  String projectId,  String storageBucket)  $default,) {final _that = this;
switch (_that) {
case _SelfHostedConfig():
return $default(_that.apiKey,_that.appId,_that.messagingSenderId,_that.projectId,_that.storageBucket);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String apiKey,  String appId,  String messagingSenderId,  String projectId,  String storageBucket)?  $default,) {final _that = this;
switch (_that) {
case _SelfHostedConfig() when $default != null:
return $default(_that.apiKey,_that.appId,_that.messagingSenderId,_that.projectId,_that.storageBucket);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SelfHostedConfig extends SelfHostedConfig {
  const _SelfHostedConfig({required this.apiKey, required this.appId, this.messagingSenderId = '', required this.projectId, this.storageBucket = ''}): super._();
  factory _SelfHostedConfig.fromJson(Map<String, dynamic> json) => _$SelfHostedConfigFromJson(json);

@override final  String apiKey;
@override final  String appId;
@override@JsonKey() final  String messagingSenderId;
@override final  String projectId;
@override@JsonKey() final  String storageBucket;

/// Create a copy of SelfHostedConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelfHostedConfigCopyWith<_SelfHostedConfig> get copyWith => __$SelfHostedConfigCopyWithImpl<_SelfHostedConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SelfHostedConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelfHostedConfig&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.messagingSenderId, messagingSenderId) || other.messagingSenderId == messagingSenderId)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.storageBucket, storageBucket) || other.storageBucket == storageBucket));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,apiKey,appId,messagingSenderId,projectId,storageBucket);

@override
String toString() {
  return 'SelfHostedConfig(apiKey: $apiKey, appId: $appId, messagingSenderId: $messagingSenderId, projectId: $projectId, storageBucket: $storageBucket)';
}


}

/// @nodoc
abstract mixin class _$SelfHostedConfigCopyWith<$Res> implements $SelfHostedConfigCopyWith<$Res> {
  factory _$SelfHostedConfigCopyWith(_SelfHostedConfig value, $Res Function(_SelfHostedConfig) _then) = __$SelfHostedConfigCopyWithImpl;
@override @useResult
$Res call({
 String apiKey, String appId, String messagingSenderId, String projectId, String storageBucket
});




}
/// @nodoc
class __$SelfHostedConfigCopyWithImpl<$Res>
    implements _$SelfHostedConfigCopyWith<$Res> {
  __$SelfHostedConfigCopyWithImpl(this._self, this._then);

  final _SelfHostedConfig _self;
  final $Res Function(_SelfHostedConfig) _then;

/// Create a copy of SelfHostedConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? apiKey = null,Object? appId = null,Object? messagingSenderId = null,Object? projectId = null,Object? storageBucket = null,}) {
  return _then(_SelfHostedConfig(
apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,messagingSenderId: null == messagingSenderId ? _self.messagingSenderId : messagingSenderId // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,storageBucket: null == storageBucket ? _self.storageBucket : storageBucket // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
