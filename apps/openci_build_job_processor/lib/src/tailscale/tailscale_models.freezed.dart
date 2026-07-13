// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tailscale_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TailscaleDevice {

 String? get os; bool? get connectedToControl; List<String>? get addresses;
/// Create a copy of TailscaleDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailscaleDeviceCopyWith<TailscaleDevice> get copyWith => _$TailscaleDeviceCopyWithImpl<TailscaleDevice>(this as TailscaleDevice, _$identity);

  /// Serializes this TailscaleDevice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscaleDevice&&(identical(other.os, os) || other.os == os)&&(identical(other.connectedToControl, connectedToControl) || other.connectedToControl == connectedToControl)&&const DeepCollectionEquality().equals(other.addresses, addresses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,os,connectedToControl,const DeepCollectionEquality().hash(addresses));

@override
String toString() {
  return 'TailscaleDevice(os: $os, connectedToControl: $connectedToControl, addresses: $addresses)';
}


}

/// @nodoc
abstract mixin class $TailscaleDeviceCopyWith<$Res>  {
  factory $TailscaleDeviceCopyWith(TailscaleDevice value, $Res Function(TailscaleDevice) _then) = _$TailscaleDeviceCopyWithImpl;
@useResult
$Res call({
 String? os, bool? connectedToControl, List<String>? addresses
});




}
/// @nodoc
class _$TailscaleDeviceCopyWithImpl<$Res>
    implements $TailscaleDeviceCopyWith<$Res> {
  _$TailscaleDeviceCopyWithImpl(this._self, this._then);

  final TailscaleDevice _self;
  final $Res Function(TailscaleDevice) _then;

/// Create a copy of TailscaleDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? os = freezed,Object? connectedToControl = freezed,Object? addresses = freezed,}) {
  return _then(_self.copyWith(
os: freezed == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String?,connectedToControl: freezed == connectedToControl ? _self.connectedToControl : connectedToControl // ignore: cast_nullable_to_non_nullable
as bool?,addresses: freezed == addresses ? _self.addresses : addresses // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [TailscaleDevice].
extension TailscaleDevicePatterns on TailscaleDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailscaleDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailscaleDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailscaleDevice value)  $default,){
final _that = this;
switch (_that) {
case _TailscaleDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailscaleDevice value)?  $default,){
final _that = this;
switch (_that) {
case _TailscaleDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? os,  bool? connectedToControl,  List<String>? addresses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscaleDevice() when $default != null:
return $default(_that.os,_that.connectedToControl,_that.addresses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? os,  bool? connectedToControl,  List<String>? addresses)  $default,) {final _that = this;
switch (_that) {
case _TailscaleDevice():
return $default(_that.os,_that.connectedToControl,_that.addresses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? os,  bool? connectedToControl,  List<String>? addresses)?  $default,) {final _that = this;
switch (_that) {
case _TailscaleDevice() when $default != null:
return $default(_that.os,_that.connectedToControl,_that.addresses);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailscaleDevice implements TailscaleDevice {
  const _TailscaleDevice({required this.os, required this.connectedToControl, required final  List<String>? addresses}): _addresses = addresses;
  factory _TailscaleDevice.fromJson(Map<String, dynamic> json) => _$TailscaleDeviceFromJson(json);

@override final  String? os;
@override final  bool? connectedToControl;
 final  List<String>? _addresses;
@override List<String>? get addresses {
  final value = _addresses;
  if (value == null) return null;
  if (_addresses is EqualUnmodifiableListView) return _addresses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of TailscaleDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailscaleDeviceCopyWith<_TailscaleDevice> get copyWith => __$TailscaleDeviceCopyWithImpl<_TailscaleDevice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailscaleDeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscaleDevice&&(identical(other.os, os) || other.os == os)&&(identical(other.connectedToControl, connectedToControl) || other.connectedToControl == connectedToControl)&&const DeepCollectionEquality().equals(other._addresses, _addresses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,os,connectedToControl,const DeepCollectionEquality().hash(_addresses));

@override
String toString() {
  return 'TailscaleDevice(os: $os, connectedToControl: $connectedToControl, addresses: $addresses)';
}


}

/// @nodoc
abstract mixin class _$TailscaleDeviceCopyWith<$Res> implements $TailscaleDeviceCopyWith<$Res> {
  factory _$TailscaleDeviceCopyWith(_TailscaleDevice value, $Res Function(_TailscaleDevice) _then) = __$TailscaleDeviceCopyWithImpl;
@override @useResult
$Res call({
 String? os, bool? connectedToControl, List<String>? addresses
});




}
/// @nodoc
class __$TailscaleDeviceCopyWithImpl<$Res>
    implements _$TailscaleDeviceCopyWith<$Res> {
  __$TailscaleDeviceCopyWithImpl(this._self, this._then);

  final _TailscaleDevice _self;
  final $Res Function(_TailscaleDevice) _then;

/// Create a copy of TailscaleDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? os = freezed,Object? connectedToControl = freezed,Object? addresses = freezed,}) {
  return _then(_TailscaleDevice(
os: freezed == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String?,connectedToControl: freezed == connectedToControl ? _self.connectedToControl : connectedToControl // ignore: cast_nullable_to_non_nullable
as bool?,addresses: freezed == addresses ? _self._addresses : addresses // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}


/// @nodoc
mixin _$TailscaleDevicesResponse {

 List<TailscaleDevice>? get devices;
/// Create a copy of TailscaleDevicesResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailscaleDevicesResponseCopyWith<TailscaleDevicesResponse> get copyWith => _$TailscaleDevicesResponseCopyWithImpl<TailscaleDevicesResponse>(this as TailscaleDevicesResponse, _$identity);

  /// Serializes this TailscaleDevicesResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailscaleDevicesResponse&&const DeepCollectionEquality().equals(other.devices, devices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(devices));

@override
String toString() {
  return 'TailscaleDevicesResponse(devices: $devices)';
}


}

/// @nodoc
abstract mixin class $TailscaleDevicesResponseCopyWith<$Res>  {
  factory $TailscaleDevicesResponseCopyWith(TailscaleDevicesResponse value, $Res Function(TailscaleDevicesResponse) _then) = _$TailscaleDevicesResponseCopyWithImpl;
@useResult
$Res call({
 List<TailscaleDevice>? devices
});




}
/// @nodoc
class _$TailscaleDevicesResponseCopyWithImpl<$Res>
    implements $TailscaleDevicesResponseCopyWith<$Res> {
  _$TailscaleDevicesResponseCopyWithImpl(this._self, this._then);

  final TailscaleDevicesResponse _self;
  final $Res Function(TailscaleDevicesResponse) _then;

/// Create a copy of TailscaleDevicesResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? devices = freezed,}) {
  return _then(_self.copyWith(
devices: freezed == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as List<TailscaleDevice>?,
  ));
}

}


/// Adds pattern-matching-related methods to [TailscaleDevicesResponse].
extension TailscaleDevicesResponsePatterns on TailscaleDevicesResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailscaleDevicesResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailscaleDevicesResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailscaleDevicesResponse value)  $default,){
final _that = this;
switch (_that) {
case _TailscaleDevicesResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailscaleDevicesResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TailscaleDevicesResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TailscaleDevice>? devices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailscaleDevicesResponse() when $default != null:
return $default(_that.devices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TailscaleDevice>? devices)  $default,) {final _that = this;
switch (_that) {
case _TailscaleDevicesResponse():
return $default(_that.devices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TailscaleDevice>? devices)?  $default,) {final _that = this;
switch (_that) {
case _TailscaleDevicesResponse() when $default != null:
return $default(_that.devices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailscaleDevicesResponse implements TailscaleDevicesResponse {
  const _TailscaleDevicesResponse({required final  List<TailscaleDevice>? devices}): _devices = devices;
  factory _TailscaleDevicesResponse.fromJson(Map<String, dynamic> json) => _$TailscaleDevicesResponseFromJson(json);

 final  List<TailscaleDevice>? _devices;
@override List<TailscaleDevice>? get devices {
  final value = _devices;
  if (value == null) return null;
  if (_devices is EqualUnmodifiableListView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of TailscaleDevicesResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailscaleDevicesResponseCopyWith<_TailscaleDevicesResponse> get copyWith => __$TailscaleDevicesResponseCopyWithImpl<_TailscaleDevicesResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailscaleDevicesResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailscaleDevicesResponse&&const DeepCollectionEquality().equals(other._devices, _devices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_devices));

@override
String toString() {
  return 'TailscaleDevicesResponse(devices: $devices)';
}


}

/// @nodoc
abstract mixin class _$TailscaleDevicesResponseCopyWith<$Res> implements $TailscaleDevicesResponseCopyWith<$Res> {
  factory _$TailscaleDevicesResponseCopyWith(_TailscaleDevicesResponse value, $Res Function(_TailscaleDevicesResponse) _then) = __$TailscaleDevicesResponseCopyWithImpl;
@override @useResult
$Res call({
 List<TailscaleDevice>? devices
});




}
/// @nodoc
class __$TailscaleDevicesResponseCopyWithImpl<$Res>
    implements _$TailscaleDevicesResponseCopyWith<$Res> {
  __$TailscaleDevicesResponseCopyWithImpl(this._self, this._then);

  final _TailscaleDevicesResponse _self;
  final $Res Function(_TailscaleDevicesResponse) _then;

/// Create a copy of TailscaleDevicesResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? devices = freezed,}) {
  return _then(_TailscaleDevicesResponse(
devices: freezed == devices ? _self._devices : devices // ignore: cast_nullable_to_non_nullable
as List<TailscaleDevice>?,
  ));
}


}

// dart format on
