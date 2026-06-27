// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OpenCIUser {

 String get id; Map<String, String> get teamUdids; Map<String, String> get teamDeviceProducts; Map<String, String> get teamDeviceOsVersions;
/// Create a copy of OpenCIUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenCIUserCopyWith<OpenCIUser> get copyWith => _$OpenCIUserCopyWithImpl<OpenCIUser>(this as OpenCIUser, _$identity);

  /// Serializes this OpenCIUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenCIUser&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.teamUdids, teamUdids)&&const DeepCollectionEquality().equals(other.teamDeviceProducts, teamDeviceProducts)&&const DeepCollectionEquality().equals(other.teamDeviceOsVersions, teamDeviceOsVersions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(teamUdids),const DeepCollectionEquality().hash(teamDeviceProducts),const DeepCollectionEquality().hash(teamDeviceOsVersions));

@override
String toString() {
  return 'OpenCIUser(id: $id, teamUdids: $teamUdids, teamDeviceProducts: $teamDeviceProducts, teamDeviceOsVersions: $teamDeviceOsVersions)';
}


}

/// @nodoc
abstract mixin class $OpenCIUserCopyWith<$Res>  {
  factory $OpenCIUserCopyWith(OpenCIUser value, $Res Function(OpenCIUser) _then) = _$OpenCIUserCopyWithImpl;
@useResult
$Res call({
 String id, Map<String, String> teamUdids, Map<String, String> teamDeviceProducts, Map<String, String> teamDeviceOsVersions
});




}
/// @nodoc
class _$OpenCIUserCopyWithImpl<$Res>
    implements $OpenCIUserCopyWith<$Res> {
  _$OpenCIUserCopyWithImpl(this._self, this._then);

  final OpenCIUser _self;
  final $Res Function(OpenCIUser) _then;

/// Create a copy of OpenCIUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? teamUdids = null,Object? teamDeviceProducts = null,Object? teamDeviceOsVersions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teamUdids: null == teamUdids ? _self.teamUdids : teamUdids // ignore: cast_nullable_to_non_nullable
as Map<String, String>,teamDeviceProducts: null == teamDeviceProducts ? _self.teamDeviceProducts : teamDeviceProducts // ignore: cast_nullable_to_non_nullable
as Map<String, String>,teamDeviceOsVersions: null == teamDeviceOsVersions ? _self.teamDeviceOsVersions : teamDeviceOsVersions // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenCIUser].
extension OpenCIUserPatterns on OpenCIUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenCIUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenCIUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenCIUser value)  $default,){
final _that = this;
switch (_that) {
case _OpenCIUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenCIUser value)?  $default,){
final _that = this;
switch (_that) {
case _OpenCIUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Map<String, String> teamUdids,  Map<String, String> teamDeviceProducts,  Map<String, String> teamDeviceOsVersions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenCIUser() when $default != null:
return $default(_that.id,_that.teamUdids,_that.teamDeviceProducts,_that.teamDeviceOsVersions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Map<String, String> teamUdids,  Map<String, String> teamDeviceProducts,  Map<String, String> teamDeviceOsVersions)  $default,) {final _that = this;
switch (_that) {
case _OpenCIUser():
return $default(_that.id,_that.teamUdids,_that.teamDeviceProducts,_that.teamDeviceOsVersions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Map<String, String> teamUdids,  Map<String, String> teamDeviceProducts,  Map<String, String> teamDeviceOsVersions)?  $default,) {final _that = this;
switch (_that) {
case _OpenCIUser() when $default != null:
return $default(_that.id,_that.teamUdids,_that.teamDeviceProducts,_that.teamDeviceOsVersions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenCIUser extends OpenCIUser {
  const _OpenCIUser({required this.id, final  Map<String, String> teamUdids = const {}, final  Map<String, String> teamDeviceProducts = const {}, final  Map<String, String> teamDeviceOsVersions = const {}}): _teamUdids = teamUdids,_teamDeviceProducts = teamDeviceProducts,_teamDeviceOsVersions = teamDeviceOsVersions,super._();
  factory _OpenCIUser.fromJson(Map<String, dynamic> json) => _$OpenCIUserFromJson(json);

@override final  String id;
 final  Map<String, String> _teamUdids;
@override@JsonKey() Map<String, String> get teamUdids {
  if (_teamUdids is EqualUnmodifiableMapView) return _teamUdids;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_teamUdids);
}

 final  Map<String, String> _teamDeviceProducts;
@override@JsonKey() Map<String, String> get teamDeviceProducts {
  if (_teamDeviceProducts is EqualUnmodifiableMapView) return _teamDeviceProducts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_teamDeviceProducts);
}

 final  Map<String, String> _teamDeviceOsVersions;
@override@JsonKey() Map<String, String> get teamDeviceOsVersions {
  if (_teamDeviceOsVersions is EqualUnmodifiableMapView) return _teamDeviceOsVersions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_teamDeviceOsVersions);
}


/// Create a copy of OpenCIUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenCIUserCopyWith<_OpenCIUser> get copyWith => __$OpenCIUserCopyWithImpl<_OpenCIUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenCIUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenCIUser&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._teamUdids, _teamUdids)&&const DeepCollectionEquality().equals(other._teamDeviceProducts, _teamDeviceProducts)&&const DeepCollectionEquality().equals(other._teamDeviceOsVersions, _teamDeviceOsVersions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_teamUdids),const DeepCollectionEquality().hash(_teamDeviceProducts),const DeepCollectionEquality().hash(_teamDeviceOsVersions));

@override
String toString() {
  return 'OpenCIUser(id: $id, teamUdids: $teamUdids, teamDeviceProducts: $teamDeviceProducts, teamDeviceOsVersions: $teamDeviceOsVersions)';
}


}

/// @nodoc
abstract mixin class _$OpenCIUserCopyWith<$Res> implements $OpenCIUserCopyWith<$Res> {
  factory _$OpenCIUserCopyWith(_OpenCIUser value, $Res Function(_OpenCIUser) _then) = __$OpenCIUserCopyWithImpl;
@override @useResult
$Res call({
 String id, Map<String, String> teamUdids, Map<String, String> teamDeviceProducts, Map<String, String> teamDeviceOsVersions
});




}
/// @nodoc
class __$OpenCIUserCopyWithImpl<$Res>
    implements _$OpenCIUserCopyWith<$Res> {
  __$OpenCIUserCopyWithImpl(this._self, this._then);

  final _OpenCIUser _self;
  final $Res Function(_OpenCIUser) _then;

/// Create a copy of OpenCIUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? teamUdids = null,Object? teamDeviceProducts = null,Object? teamDeviceOsVersions = null,}) {
  return _then(_OpenCIUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teamUdids: null == teamUdids ? _self._teamUdids : teamUdids // ignore: cast_nullable_to_non_nullable
as Map<String, String>,teamDeviceProducts: null == teamDeviceProducts ? _self._teamDeviceProducts : teamDeviceProducts // ignore: cast_nullable_to_non_nullable
as Map<String, String>,teamDeviceOsVersions: null == teamDeviceOsVersions ? _self._teamDeviceOsVersions : teamDeviceOsVersions // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
