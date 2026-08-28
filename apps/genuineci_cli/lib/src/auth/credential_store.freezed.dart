// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credential_store.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthProfile {

@JsonKey(name: 'server_url') String get serverUrl; String get token;@JsonKey(name: 'team_id') String get teamId;@JsonKey(name: 'auth_type') String get authType;
/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthProfileCopyWith<AuthProfile> get copyWith => _$AuthProfileCopyWithImpl<AuthProfile>(this as AuthProfile, _$identity);

  /// Serializes this AuthProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthProfile&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.token, token) || other.token == token)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.authType, authType) || other.authType == authType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverUrl,token,teamId,authType);



}

/// @nodoc
abstract mixin class $AuthProfileCopyWith<$Res>  {
  factory $AuthProfileCopyWith(AuthProfile value, $Res Function(AuthProfile) _then) = _$AuthProfileCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'server_url') String serverUrl, String token,@JsonKey(name: 'team_id') String teamId,@JsonKey(name: 'auth_type') String authType
});




}
/// @nodoc
class _$AuthProfileCopyWithImpl<$Res>
    implements $AuthProfileCopyWith<$Res> {
  _$AuthProfileCopyWithImpl(this._self, this._then);

  final AuthProfile _self;
  final $Res Function(AuthProfile) _then;

/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverUrl = null,Object? token = null,Object? teamId = null,Object? authType = null,}) {
  return _then(_self.copyWith(
serverUrl: null == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,authType: null == authType ? _self.authType : authType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthProfile].
extension AuthProfilePatterns on AuthProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthProfile value)  $default,){
final _that = this;
switch (_that) {
case _AuthProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthProfile value)?  $default,){
final _that = this;
switch (_that) {
case _AuthProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'server_url')  String serverUrl,  String token, @JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'auth_type')  String authType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthProfile() when $default != null:
return $default(_that.serverUrl,_that.token,_that.teamId,_that.authType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'server_url')  String serverUrl,  String token, @JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'auth_type')  String authType)  $default,) {final _that = this;
switch (_that) {
case _AuthProfile():
return $default(_that.serverUrl,_that.token,_that.teamId,_that.authType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'server_url')  String serverUrl,  String token, @JsonKey(name: 'team_id')  String teamId, @JsonKey(name: 'auth_type')  String authType)?  $default,) {final _that = this;
switch (_that) {
case _AuthProfile() when $default != null:
return $default(_that.serverUrl,_that.token,_that.teamId,_that.authType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthProfile extends AuthProfile {
  const _AuthProfile({@JsonKey(name: 'server_url') this.serverUrl = 'http://localhost:8080', this.token = '', @JsonKey(name: 'team_id') this.teamId = '', @JsonKey(name: 'auth_type') this.authType = 'api_key'}): super._();
  factory _AuthProfile.fromJson(Map<String, dynamic> json) => _$AuthProfileFromJson(json);

@override@JsonKey(name: 'server_url') final  String serverUrl;
@override@JsonKey() final  String token;
@override@JsonKey(name: 'team_id') final  String teamId;
@override@JsonKey(name: 'auth_type') final  String authType;

/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthProfileCopyWith<_AuthProfile> get copyWith => __$AuthProfileCopyWithImpl<_AuthProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthProfile&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.token, token) || other.token == token)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.authType, authType) || other.authType == authType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverUrl,token,teamId,authType);



}

/// @nodoc
abstract mixin class _$AuthProfileCopyWith<$Res> implements $AuthProfileCopyWith<$Res> {
  factory _$AuthProfileCopyWith(_AuthProfile value, $Res Function(_AuthProfile) _then) = __$AuthProfileCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'server_url') String serverUrl, String token,@JsonKey(name: 'team_id') String teamId,@JsonKey(name: 'auth_type') String authType
});




}
/// @nodoc
class __$AuthProfileCopyWithImpl<$Res>
    implements _$AuthProfileCopyWith<$Res> {
  __$AuthProfileCopyWithImpl(this._self, this._then);

  final _AuthProfile _self;
  final $Res Function(_AuthProfile) _then;

/// Create a copy of AuthProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverUrl = null,Object? token = null,Object? teamId = null,Object? authType = null,}) {
  return _then(_AuthProfile(
serverUrl: null == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,authType: null == authType ? _self.authType : authType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CredentialConfig {

@JsonKey(name: 'active_profile') String get activeProfile; Map<String, AuthProfile> get profiles;
/// Create a copy of CredentialConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CredentialConfigCopyWith<CredentialConfig> get copyWith => _$CredentialConfigCopyWithImpl<CredentialConfig>(this as CredentialConfig, _$identity);

  /// Serializes this CredentialConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CredentialConfig&&(identical(other.activeProfile, activeProfile) || other.activeProfile == activeProfile)&&const DeepCollectionEquality().equals(other.profiles, profiles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeProfile,const DeepCollectionEquality().hash(profiles));

@override
String toString() {
  return 'CredentialConfig(activeProfile: $activeProfile, profiles: $profiles)';
}


}

/// @nodoc
abstract mixin class $CredentialConfigCopyWith<$Res>  {
  factory $CredentialConfigCopyWith(CredentialConfig value, $Res Function(CredentialConfig) _then) = _$CredentialConfigCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'active_profile') String activeProfile, Map<String, AuthProfile> profiles
});




}
/// @nodoc
class _$CredentialConfigCopyWithImpl<$Res>
    implements $CredentialConfigCopyWith<$Res> {
  _$CredentialConfigCopyWithImpl(this._self, this._then);

  final CredentialConfig _self;
  final $Res Function(CredentialConfig) _then;

/// Create a copy of CredentialConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeProfile = null,Object? profiles = null,}) {
  return _then(_self.copyWith(
activeProfile: null == activeProfile ? _self.activeProfile : activeProfile // ignore: cast_nullable_to_non_nullable
as String,profiles: null == profiles ? _self.profiles : profiles // ignore: cast_nullable_to_non_nullable
as Map<String, AuthProfile>,
  ));
}

}


/// Adds pattern-matching-related methods to [CredentialConfig].
extension CredentialConfigPatterns on CredentialConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CredentialConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CredentialConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CredentialConfig value)  $default,){
final _that = this;
switch (_that) {
case _CredentialConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CredentialConfig value)?  $default,){
final _that = this;
switch (_that) {
case _CredentialConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'active_profile')  String activeProfile,  Map<String, AuthProfile> profiles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CredentialConfig() when $default != null:
return $default(_that.activeProfile,_that.profiles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'active_profile')  String activeProfile,  Map<String, AuthProfile> profiles)  $default,) {final _that = this;
switch (_that) {
case _CredentialConfig():
return $default(_that.activeProfile,_that.profiles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'active_profile')  String activeProfile,  Map<String, AuthProfile> profiles)?  $default,) {final _that = this;
switch (_that) {
case _CredentialConfig() when $default != null:
return $default(_that.activeProfile,_that.profiles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CredentialConfig implements CredentialConfig {
  const _CredentialConfig({@JsonKey(name: 'active_profile') this.activeProfile = 'default', final  Map<String, AuthProfile> profiles = const {}}): _profiles = profiles;
  factory _CredentialConfig.fromJson(Map<String, dynamic> json) => _$CredentialConfigFromJson(json);

@override@JsonKey(name: 'active_profile') final  String activeProfile;
 final  Map<String, AuthProfile> _profiles;
@override@JsonKey() Map<String, AuthProfile> get profiles {
  if (_profiles is EqualUnmodifiableMapView) return _profiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_profiles);
}


/// Create a copy of CredentialConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CredentialConfigCopyWith<_CredentialConfig> get copyWith => __$CredentialConfigCopyWithImpl<_CredentialConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CredentialConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CredentialConfig&&(identical(other.activeProfile, activeProfile) || other.activeProfile == activeProfile)&&const DeepCollectionEquality().equals(other._profiles, _profiles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeProfile,const DeepCollectionEquality().hash(_profiles));

@override
String toString() {
  return 'CredentialConfig(activeProfile: $activeProfile, profiles: $profiles)';
}


}

/// @nodoc
abstract mixin class _$CredentialConfigCopyWith<$Res> implements $CredentialConfigCopyWith<$Res> {
  factory _$CredentialConfigCopyWith(_CredentialConfig value, $Res Function(_CredentialConfig) _then) = __$CredentialConfigCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'active_profile') String activeProfile, Map<String, AuthProfile> profiles
});




}
/// @nodoc
class __$CredentialConfigCopyWithImpl<$Res>
    implements _$CredentialConfigCopyWith<$Res> {
  __$CredentialConfigCopyWithImpl(this._self, this._then);

  final _CredentialConfig _self;
  final $Res Function(_CredentialConfig) _then;

/// Create a copy of CredentialConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeProfile = null,Object? profiles = null,}) {
  return _then(_CredentialConfig(
activeProfile: null == activeProfile ? _self.activeProfile : activeProfile // ignore: cast_nullable_to_non_nullable
as String,profiles: null == profiles ? _self._profiles : profiles // ignore: cast_nullable_to_non_nullable
as Map<String, AuthProfile>,
  ));
}


}

// dart format on
