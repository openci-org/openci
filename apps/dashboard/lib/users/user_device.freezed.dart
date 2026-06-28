// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserDevice {

 String get id; String get userId; String get teamId; String get udid; String get deviceProduct; String get deviceOsVersion; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of UserDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDeviceCopyWith<UserDevice> get copyWith => _$UserDeviceCopyWithImpl<UserDevice>(this as UserDevice, _$identity);

  /// Serializes this UserDevice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.udid, udid) || other.udid == udid)&&(identical(other.deviceProduct, deviceProduct) || other.deviceProduct == deviceProduct)&&(identical(other.deviceOsVersion, deviceOsVersion) || other.deviceOsVersion == deviceOsVersion)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,teamId,udid,deviceProduct,deviceOsVersion,createdAt,updatedAt);

@override
String toString() {
  return 'UserDevice(id: $id, userId: $userId, teamId: $teamId, udid: $udid, deviceProduct: $deviceProduct, deviceOsVersion: $deviceOsVersion, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UserDeviceCopyWith<$Res>  {
  factory $UserDeviceCopyWith(UserDevice value, $Res Function(UserDevice) _then) = _$UserDeviceCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String teamId, String udid, String deviceProduct, String deviceOsVersion, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$UserDeviceCopyWithImpl<$Res>
    implements $UserDeviceCopyWith<$Res> {
  _$UserDeviceCopyWithImpl(this._self, this._then);

  final UserDevice _self;
  final $Res Function(UserDevice) _then;

/// Create a copy of UserDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? teamId = null,Object? udid = null,Object? deviceProduct = null,Object? deviceOsVersion = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,udid: null == udid ? _self.udid : udid // ignore: cast_nullable_to_non_nullable
as String,deviceProduct: null == deviceProduct ? _self.deviceProduct : deviceProduct // ignore: cast_nullable_to_non_nullable
as String,deviceOsVersion: null == deviceOsVersion ? _self.deviceOsVersion : deviceOsVersion // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UserDevice].
extension UserDevicePatterns on UserDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserDevice value)  $default,){
final _that = this;
switch (_that) {
case _UserDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserDevice value)?  $default,){
final _that = this;
switch (_that) {
case _UserDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String teamId,  String udid,  String deviceProduct,  String deviceOsVersion,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserDevice() when $default != null:
return $default(_that.id,_that.userId,_that.teamId,_that.udid,_that.deviceProduct,_that.deviceOsVersion,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String teamId,  String udid,  String deviceProduct,  String deviceOsVersion,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _UserDevice():
return $default(_that.id,_that.userId,_that.teamId,_that.udid,_that.deviceProduct,_that.deviceOsVersion,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String teamId,  String udid,  String deviceProduct,  String deviceOsVersion,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserDevice() when $default != null:
return $default(_that.id,_that.userId,_that.teamId,_that.udid,_that.deviceProduct,_that.deviceOsVersion,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserDevice implements UserDevice {
  const _UserDevice({required this.id, required this.userId, required this.teamId, required this.udid, required this.deviceProduct, required this.deviceOsVersion, required this.createdAt, required this.updatedAt});
  factory _UserDevice.fromJson(Map<String, dynamic> json) => _$UserDeviceFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String teamId;
@override final  String udid;
@override final  String deviceProduct;
@override final  String deviceOsVersion;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of UserDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDeviceCopyWith<_UserDevice> get copyWith => __$UserDeviceCopyWithImpl<_UserDevice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserDeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.udid, udid) || other.udid == udid)&&(identical(other.deviceProduct, deviceProduct) || other.deviceProduct == deviceProduct)&&(identical(other.deviceOsVersion, deviceOsVersion) || other.deviceOsVersion == deviceOsVersion)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,teamId,udid,deviceProduct,deviceOsVersion,createdAt,updatedAt);

@override
String toString() {
  return 'UserDevice(id: $id, userId: $userId, teamId: $teamId, udid: $udid, deviceProduct: $deviceProduct, deviceOsVersion: $deviceOsVersion, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UserDeviceCopyWith<$Res> implements $UserDeviceCopyWith<$Res> {
  factory _$UserDeviceCopyWith(_UserDevice value, $Res Function(_UserDevice) _then) = __$UserDeviceCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String teamId, String udid, String deviceProduct, String deviceOsVersion, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$UserDeviceCopyWithImpl<$Res>
    implements _$UserDeviceCopyWith<$Res> {
  __$UserDeviceCopyWithImpl(this._self, this._then);

  final _UserDevice _self;
  final $Res Function(_UserDevice) _then;

/// Create a copy of UserDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? teamId = null,Object? udid = null,Object? deviceProduct = null,Object? deviceOsVersion = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_UserDevice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,udid: null == udid ? _self.udid : udid // ignore: cast_nullable_to_non_nullable
as String,deviceProduct: null == deviceProduct ? _self.deviceProduct : deviceProduct // ignore: cast_nullable_to_non_nullable
as String,deviceOsVersion: null == deviceOsVersion ? _self.deviceOsVersion : deviceOsVersion // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
