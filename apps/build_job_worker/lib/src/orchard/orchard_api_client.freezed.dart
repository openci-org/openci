// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'orchard_api_client.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrchardLease {

 String get id; String get vmName; String get status; String? get ipAddress; int? get sshPort;
/// Create a copy of OrchardLease
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrchardLeaseCopyWith<OrchardLease> get copyWith => _$OrchardLeaseCopyWithImpl<OrchardLease>(this as OrchardLease, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrchardLease&&(identical(other.id, id) || other.id == id)&&(identical(other.vmName, vmName) || other.vmName == vmName)&&(identical(other.status, status) || other.status == status)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.sshPort, sshPort) || other.sshPort == sshPort));
}


@override
int get hashCode => Object.hash(runtimeType,id,vmName,status,ipAddress,sshPort);

@override
String toString() {
  return 'OrchardLease(id: $id, vmName: $vmName, status: $status, ipAddress: $ipAddress, sshPort: $sshPort)';
}


}

/// @nodoc
abstract mixin class $OrchardLeaseCopyWith<$Res>  {
  factory $OrchardLeaseCopyWith(OrchardLease value, $Res Function(OrchardLease) _then) = _$OrchardLeaseCopyWithImpl;
@useResult
$Res call({
 String id, String vmName, String status, String? ipAddress, int? sshPort
});




}
/// @nodoc
class _$OrchardLeaseCopyWithImpl<$Res>
    implements $OrchardLeaseCopyWith<$Res> {
  _$OrchardLeaseCopyWithImpl(this._self, this._then);

  final OrchardLease _self;
  final $Res Function(OrchardLease) _then;

/// Create a copy of OrchardLease
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vmName = null,Object? status = null,Object? ipAddress = freezed,Object? sshPort = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vmName: null == vmName ? _self.vmName : vmName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,sshPort: freezed == sshPort ? _self.sshPort : sshPort // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrchardLease].
extension OrchardLeasePatterns on OrchardLease {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrchardLease value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrchardLease() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrchardLease value)  $default,){
final _that = this;
switch (_that) {
case _OrchardLease():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrchardLease value)?  $default,){
final _that = this;
switch (_that) {
case _OrchardLease() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String vmName,  String status,  String? ipAddress,  int? sshPort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrchardLease() when $default != null:
return $default(_that.id,_that.vmName,_that.status,_that.ipAddress,_that.sshPort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String vmName,  String status,  String? ipAddress,  int? sshPort)  $default,) {final _that = this;
switch (_that) {
case _OrchardLease():
return $default(_that.id,_that.vmName,_that.status,_that.ipAddress,_that.sshPort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String vmName,  String status,  String? ipAddress,  int? sshPort)?  $default,) {final _that = this;
switch (_that) {
case _OrchardLease() when $default != null:
return $default(_that.id,_that.vmName,_that.status,_that.ipAddress,_that.sshPort);case _:
  return null;

}
}

}

/// @nodoc


class _OrchardLease implements OrchardLease {
  const _OrchardLease({required this.id, required this.vmName, required this.status, this.ipAddress, this.sshPort});


@override final  String id;
@override final  String vmName;
@override final  String status;
@override final  String? ipAddress;
@override final  int? sshPort;

/// Create a copy of OrchardLease
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrchardLeaseCopyWith<_OrchardLease> get copyWith => __$OrchardLeaseCopyWithImpl<_OrchardLease>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrchardLease&&(identical(other.id, id) || other.id == id)&&(identical(other.vmName, vmName) || other.vmName == vmName)&&(identical(other.status, status) || other.status == status)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.sshPort, sshPort) || other.sshPort == sshPort));
}


@override
int get hashCode => Object.hash(runtimeType,id,vmName,status,ipAddress,sshPort);

@override
String toString() {
  return 'OrchardLease(id: $id, vmName: $vmName, status: $status, ipAddress: $ipAddress, sshPort: $sshPort)';
}


}

/// @nodoc
abstract mixin class _$OrchardLeaseCopyWith<$Res> implements $OrchardLeaseCopyWith<$Res> {
  factory _$OrchardLeaseCopyWith(_OrchardLease value, $Res Function(_OrchardLease) _then) = __$OrchardLeaseCopyWithImpl;
@override @useResult
$Res call({
 String id, String vmName, String status, String? ipAddress, int? sshPort
});




}
/// @nodoc
class __$OrchardLeaseCopyWithImpl<$Res>
    implements _$OrchardLeaseCopyWith<$Res> {
  __$OrchardLeaseCopyWithImpl(this._self, this._then);

  final _OrchardLease _self;
  final $Res Function(_OrchardLease) _then;

/// Create a copy of OrchardLease
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vmName = null,Object? status = null,Object? ipAddress = freezed,Object? sshPort = freezed,}) {
  return _then(_OrchardLease(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vmName: null == vmName ? _self.vmName : vmName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,sshPort: freezed == sshPort ? _self.sshPort : sshPort // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
