// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConnectionProfile {

 String get id; String get name; String get apiUrl; Map<String, SelfHostedConfig> get firebase;
/// Create a copy of ConnectionProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectionProfileCopyWith<ConnectionProfile> get copyWith => _$ConnectionProfileCopyWithImpl<ConnectionProfile>(this as ConnectionProfile, _$identity);

  /// Serializes this ConnectionProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectionProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.apiUrl, apiUrl) || other.apiUrl == apiUrl)&&const DeepCollectionEquality().equals(other.firebase, firebase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,apiUrl,const DeepCollectionEquality().hash(firebase));

@override
String toString() {
  return 'ConnectionProfile(id: $id, name: $name, apiUrl: $apiUrl, firebase: $firebase)';
}


}

/// @nodoc
abstract mixin class $ConnectionProfileCopyWith<$Res>  {
  factory $ConnectionProfileCopyWith(ConnectionProfile value, $Res Function(ConnectionProfile) _then) = _$ConnectionProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name, String apiUrl, Map<String, SelfHostedConfig> firebase
});




}
/// @nodoc
class _$ConnectionProfileCopyWithImpl<$Res>
    implements $ConnectionProfileCopyWith<$Res> {
  _$ConnectionProfileCopyWithImpl(this._self, this._then);

  final ConnectionProfile _self;
  final $Res Function(ConnectionProfile) _then;

/// Create a copy of ConnectionProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? apiUrl = null,Object? firebase = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,apiUrl: null == apiUrl ? _self.apiUrl : apiUrl // ignore: cast_nullable_to_non_nullable
as String,firebase: null == firebase ? _self.firebase : firebase // ignore: cast_nullable_to_non_nullable
as Map<String, SelfHostedConfig>,
  ));
}

}


/// Adds pattern-matching-related methods to [ConnectionProfile].
extension ConnectionProfilePatterns on ConnectionProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConnectionProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConnectionProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConnectionProfile value)  $default,){
final _that = this;
switch (_that) {
case _ConnectionProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConnectionProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ConnectionProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String apiUrl,  Map<String, SelfHostedConfig> firebase)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConnectionProfile() when $default != null:
return $default(_that.id,_that.name,_that.apiUrl,_that.firebase);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String apiUrl,  Map<String, SelfHostedConfig> firebase)  $default,) {final _that = this;
switch (_that) {
case _ConnectionProfile():
return $default(_that.id,_that.name,_that.apiUrl,_that.firebase);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String apiUrl,  Map<String, SelfHostedConfig> firebase)?  $default,) {final _that = this;
switch (_that) {
case _ConnectionProfile() when $default != null:
return $default(_that.id,_that.name,_that.apiUrl,_that.firebase);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ConnectionProfile extends ConnectionProfile {
  const _ConnectionProfile({required this.id, required this.name, required this.apiUrl, required final  Map<String, SelfHostedConfig> firebase}): _firebase = firebase,super._();
  factory _ConnectionProfile.fromJson(Map<String, dynamic> json) => _$ConnectionProfileFromJson(json);

@override final  String id;
@override final  String name;
@override final  String apiUrl;
 final  Map<String, SelfHostedConfig> _firebase;
@override Map<String, SelfHostedConfig> get firebase {
  if (_firebase is EqualUnmodifiableMapView) return _firebase;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_firebase);
}


/// Create a copy of ConnectionProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConnectionProfileCopyWith<_ConnectionProfile> get copyWith => __$ConnectionProfileCopyWithImpl<_ConnectionProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConnectionProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConnectionProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.apiUrl, apiUrl) || other.apiUrl == apiUrl)&&const DeepCollectionEquality().equals(other._firebase, _firebase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,apiUrl,const DeepCollectionEquality().hash(_firebase));

@override
String toString() {
  return 'ConnectionProfile(id: $id, name: $name, apiUrl: $apiUrl, firebase: $firebase)';
}


}

/// @nodoc
abstract mixin class _$ConnectionProfileCopyWith<$Res> implements $ConnectionProfileCopyWith<$Res> {
  factory _$ConnectionProfileCopyWith(_ConnectionProfile value, $Res Function(_ConnectionProfile) _then) = __$ConnectionProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String apiUrl, Map<String, SelfHostedConfig> firebase
});




}
/// @nodoc
class __$ConnectionProfileCopyWithImpl<$Res>
    implements _$ConnectionProfileCopyWith<$Res> {
  __$ConnectionProfileCopyWithImpl(this._self, this._then);

  final _ConnectionProfile _self;
  final $Res Function(_ConnectionProfile) _then;

/// Create a copy of ConnectionProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? apiUrl = null,Object? firebase = null,}) {
  return _then(_ConnectionProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,apiUrl: null == apiUrl ? _self.apiUrl : apiUrl // ignore: cast_nullable_to_non_nullable
as String,firebase: null == firebase ? _self._firebase : firebase // ignore: cast_nullable_to_non_nullable
as Map<String, SelfHostedConfig>,
  ));
}


}

// dart format on
