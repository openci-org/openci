// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LumeDiskSize {

 int get allocated; int get total;
/// Create a copy of LumeDiskSize
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LumeDiskSizeCopyWith<LumeDiskSize> get copyWith => _$LumeDiskSizeCopyWithImpl<LumeDiskSize>(this as LumeDiskSize, _$identity);

  /// Serializes this LumeDiskSize to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LumeDiskSize&&(identical(other.allocated, allocated) || other.allocated == allocated)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,allocated,total);

@override
String toString() {
  return 'LumeDiskSize(allocated: $allocated, total: $total)';
}


}

/// @nodoc
abstract mixin class $LumeDiskSizeCopyWith<$Res>  {
  factory $LumeDiskSizeCopyWith(LumeDiskSize value, $Res Function(LumeDiskSize) _then) = _$LumeDiskSizeCopyWithImpl;
@useResult
$Res call({
 int allocated, int total
});




}
/// @nodoc
class _$LumeDiskSizeCopyWithImpl<$Res>
    implements $LumeDiskSizeCopyWith<$Res> {
  _$LumeDiskSizeCopyWithImpl(this._self, this._then);

  final LumeDiskSize _self;
  final $Res Function(LumeDiskSize) _then;

/// Create a copy of LumeDiskSize
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allocated = null,Object? total = null,}) {
  return _then(_self.copyWith(
allocated: null == allocated ? _self.allocated : allocated // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LumeDiskSize].
extension LumeDiskSizePatterns on LumeDiskSize {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LumeDiskSize value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LumeDiskSize() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LumeDiskSize value)  $default,){
final _that = this;
switch (_that) {
case _LumeDiskSize():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LumeDiskSize value)?  $default,){
final _that = this;
switch (_that) {
case _LumeDiskSize() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int allocated,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LumeDiskSize() when $default != null:
return $default(_that.allocated,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int allocated,  int total)  $default,) {final _that = this;
switch (_that) {
case _LumeDiskSize():
return $default(_that.allocated,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int allocated,  int total)?  $default,) {final _that = this;
switch (_that) {
case _LumeDiskSize() when $default != null:
return $default(_that.allocated,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LumeDiskSize implements LumeDiskSize {
  const _LumeDiskSize({required this.allocated, required this.total});
  factory _LumeDiskSize.fromJson(Map<String, dynamic> json) => _$LumeDiskSizeFromJson(json);

@override final  int allocated;
@override final  int total;

/// Create a copy of LumeDiskSize
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LumeDiskSizeCopyWith<_LumeDiskSize> get copyWith => __$LumeDiskSizeCopyWithImpl<_LumeDiskSize>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LumeDiskSizeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LumeDiskSize&&(identical(other.allocated, allocated) || other.allocated == allocated)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,allocated,total);

@override
String toString() {
  return 'LumeDiskSize(allocated: $allocated, total: $total)';
}


}

/// @nodoc
abstract mixin class _$LumeDiskSizeCopyWith<$Res> implements $LumeDiskSizeCopyWith<$Res> {
  factory _$LumeDiskSizeCopyWith(_LumeDiskSize value, $Res Function(_LumeDiskSize) _then) = __$LumeDiskSizeCopyWithImpl;
@override @useResult
$Res call({
 int allocated, int total
});




}
/// @nodoc
class __$LumeDiskSizeCopyWithImpl<$Res>
    implements _$LumeDiskSizeCopyWith<$Res> {
  __$LumeDiskSizeCopyWithImpl(this._self, this._then);

  final _LumeDiskSize _self;
  final $Res Function(_LumeDiskSize) _then;

/// Create a copy of LumeDiskSize
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allocated = null,Object? total = null,}) {
  return _then(_LumeDiskSize(
allocated: null == allocated ? _self.allocated : allocated // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LumeVM {

 String get name; String get status; String? get ipAddress; bool? get sshAvailable; int? get cpuCount; int? get memorySize; String? get display; String? get networkMode; String? get os; String? get locationName; String? get vncUrl; LumeDiskSize? get diskSize;
/// Create a copy of LumeVM
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LumeVMCopyWith<LumeVM> get copyWith => _$LumeVMCopyWithImpl<LumeVM>(this as LumeVM, _$identity);

  /// Serializes this LumeVM to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LumeVM&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.sshAvailable, sshAvailable) || other.sshAvailable == sshAvailable)&&(identical(other.cpuCount, cpuCount) || other.cpuCount == cpuCount)&&(identical(other.memorySize, memorySize) || other.memorySize == memorySize)&&(identical(other.display, display) || other.display == display)&&(identical(other.networkMode, networkMode) || other.networkMode == networkMode)&&(identical(other.os, os) || other.os == os)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.vncUrl, vncUrl) || other.vncUrl == vncUrl)&&(identical(other.diskSize, diskSize) || other.diskSize == diskSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,status,ipAddress,sshAvailable,cpuCount,memorySize,display,networkMode,os,locationName,vncUrl,diskSize);

@override
String toString() {
  return 'LumeVM(name: $name, status: $status, ipAddress: $ipAddress, sshAvailable: $sshAvailable, cpuCount: $cpuCount, memorySize: $memorySize, display: $display, networkMode: $networkMode, os: $os, locationName: $locationName, vncUrl: $vncUrl, diskSize: $diskSize)';
}


}

/// @nodoc
abstract mixin class $LumeVMCopyWith<$Res>  {
  factory $LumeVMCopyWith(LumeVM value, $Res Function(LumeVM) _then) = _$LumeVMCopyWithImpl;
@useResult
$Res call({
 String name, String status, String? ipAddress, bool? sshAvailable, int? cpuCount, int? memorySize, String? display, String? networkMode, String? os, String? locationName, String? vncUrl, LumeDiskSize? diskSize
});


$LumeDiskSizeCopyWith<$Res>? get diskSize;

}
/// @nodoc
class _$LumeVMCopyWithImpl<$Res>
    implements $LumeVMCopyWith<$Res> {
  _$LumeVMCopyWithImpl(this._self, this._then);

  final LumeVM _self;
  final $Res Function(LumeVM) _then;

/// Create a copy of LumeVM
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? status = null,Object? ipAddress = freezed,Object? sshAvailable = freezed,Object? cpuCount = freezed,Object? memorySize = freezed,Object? display = freezed,Object? networkMode = freezed,Object? os = freezed,Object? locationName = freezed,Object? vncUrl = freezed,Object? diskSize = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,sshAvailable: freezed == sshAvailable ? _self.sshAvailable : sshAvailable // ignore: cast_nullable_to_non_nullable
as bool?,cpuCount: freezed == cpuCount ? _self.cpuCount : cpuCount // ignore: cast_nullable_to_non_nullable
as int?,memorySize: freezed == memorySize ? _self.memorySize : memorySize // ignore: cast_nullable_to_non_nullable
as int?,display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as String?,networkMode: freezed == networkMode ? _self.networkMode : networkMode // ignore: cast_nullable_to_non_nullable
as String?,os: freezed == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,vncUrl: freezed == vncUrl ? _self.vncUrl : vncUrl // ignore: cast_nullable_to_non_nullable
as String?,diskSize: freezed == diskSize ? _self.diskSize : diskSize // ignore: cast_nullable_to_non_nullable
as LumeDiskSize?,
  ));
}
/// Create a copy of LumeVM
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LumeDiskSizeCopyWith<$Res>? get diskSize {
    if (_self.diskSize == null) {
    return null;
  }

  return $LumeDiskSizeCopyWith<$Res>(_self.diskSize!, (value) {
    return _then(_self.copyWith(diskSize: value));
  });
}
}


/// Adds pattern-matching-related methods to [LumeVM].
extension LumeVMPatterns on LumeVM {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LumeVM value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LumeVM() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LumeVM value)  $default,){
final _that = this;
switch (_that) {
case _LumeVM():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LumeVM value)?  $default,){
final _that = this;
switch (_that) {
case _LumeVM() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String status,  String? ipAddress,  bool? sshAvailable,  int? cpuCount,  int? memorySize,  String? display,  String? networkMode,  String? os,  String? locationName,  String? vncUrl,  LumeDiskSize? diskSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LumeVM() when $default != null:
return $default(_that.name,_that.status,_that.ipAddress,_that.sshAvailable,_that.cpuCount,_that.memorySize,_that.display,_that.networkMode,_that.os,_that.locationName,_that.vncUrl,_that.diskSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String status,  String? ipAddress,  bool? sshAvailable,  int? cpuCount,  int? memorySize,  String? display,  String? networkMode,  String? os,  String? locationName,  String? vncUrl,  LumeDiskSize? diskSize)  $default,) {final _that = this;
switch (_that) {
case _LumeVM():
return $default(_that.name,_that.status,_that.ipAddress,_that.sshAvailable,_that.cpuCount,_that.memorySize,_that.display,_that.networkMode,_that.os,_that.locationName,_that.vncUrl,_that.diskSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String status,  String? ipAddress,  bool? sshAvailable,  int? cpuCount,  int? memorySize,  String? display,  String? networkMode,  String? os,  String? locationName,  String? vncUrl,  LumeDiskSize? diskSize)?  $default,) {final _that = this;
switch (_that) {
case _LumeVM() when $default != null:
return $default(_that.name,_that.status,_that.ipAddress,_that.sshAvailable,_that.cpuCount,_that.memorySize,_that.display,_that.networkMode,_that.os,_that.locationName,_that.vncUrl,_that.diskSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LumeVM implements LumeVM {
  const _LumeVM({required this.name, required this.status, this.ipAddress, this.sshAvailable, this.cpuCount, this.memorySize, this.display, this.networkMode, this.os, this.locationName, this.vncUrl, this.diskSize});
  factory _LumeVM.fromJson(Map<String, dynamic> json) => _$LumeVMFromJson(json);

@override final  String name;
@override final  String status;
@override final  String? ipAddress;
@override final  bool? sshAvailable;
@override final  int? cpuCount;
@override final  int? memorySize;
@override final  String? display;
@override final  String? networkMode;
@override final  String? os;
@override final  String? locationName;
@override final  String? vncUrl;
@override final  LumeDiskSize? diskSize;

/// Create a copy of LumeVM
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LumeVMCopyWith<_LumeVM> get copyWith => __$LumeVMCopyWithImpl<_LumeVM>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LumeVMToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LumeVM&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.sshAvailable, sshAvailable) || other.sshAvailable == sshAvailable)&&(identical(other.cpuCount, cpuCount) || other.cpuCount == cpuCount)&&(identical(other.memorySize, memorySize) || other.memorySize == memorySize)&&(identical(other.display, display) || other.display == display)&&(identical(other.networkMode, networkMode) || other.networkMode == networkMode)&&(identical(other.os, os) || other.os == os)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.vncUrl, vncUrl) || other.vncUrl == vncUrl)&&(identical(other.diskSize, diskSize) || other.diskSize == diskSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,status,ipAddress,sshAvailable,cpuCount,memorySize,display,networkMode,os,locationName,vncUrl,diskSize);

@override
String toString() {
  return 'LumeVM(name: $name, status: $status, ipAddress: $ipAddress, sshAvailable: $sshAvailable, cpuCount: $cpuCount, memorySize: $memorySize, display: $display, networkMode: $networkMode, os: $os, locationName: $locationName, vncUrl: $vncUrl, diskSize: $diskSize)';
}


}

/// @nodoc
abstract mixin class _$LumeVMCopyWith<$Res> implements $LumeVMCopyWith<$Res> {
  factory _$LumeVMCopyWith(_LumeVM value, $Res Function(_LumeVM) _then) = __$LumeVMCopyWithImpl;
@override @useResult
$Res call({
 String name, String status, String? ipAddress, bool? sshAvailable, int? cpuCount, int? memorySize, String? display, String? networkMode, String? os, String? locationName, String? vncUrl, LumeDiskSize? diskSize
});


@override $LumeDiskSizeCopyWith<$Res>? get diskSize;

}
/// @nodoc
class __$LumeVMCopyWithImpl<$Res>
    implements _$LumeVMCopyWith<$Res> {
  __$LumeVMCopyWithImpl(this._self, this._then);

  final _LumeVM _self;
  final $Res Function(_LumeVM) _then;

/// Create a copy of LumeVM
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? status = null,Object? ipAddress = freezed,Object? sshAvailable = freezed,Object? cpuCount = freezed,Object? memorySize = freezed,Object? display = freezed,Object? networkMode = freezed,Object? os = freezed,Object? locationName = freezed,Object? vncUrl = freezed,Object? diskSize = freezed,}) {
  return _then(_LumeVM(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,sshAvailable: freezed == sshAvailable ? _self.sshAvailable : sshAvailable // ignore: cast_nullable_to_non_nullable
as bool?,cpuCount: freezed == cpuCount ? _self.cpuCount : cpuCount // ignore: cast_nullable_to_non_nullable
as int?,memorySize: freezed == memorySize ? _self.memorySize : memorySize // ignore: cast_nullable_to_non_nullable
as int?,display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as String?,networkMode: freezed == networkMode ? _self.networkMode : networkMode // ignore: cast_nullable_to_non_nullable
as String?,os: freezed == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,vncUrl: freezed == vncUrl ? _self.vncUrl : vncUrl // ignore: cast_nullable_to_non_nullable
as String?,diskSize: freezed == diskSize ? _self.diskSize : diskSize // ignore: cast_nullable_to_non_nullable
as LumeDiskSize?,
  ));
}

/// Create a copy of LumeVM
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LumeDiskSizeCopyWith<$Res>? get diskSize {
    if (_self.diskSize == null) {
    return null;
  }

  return $LumeDiskSizeCopyWith<$Res>(_self.diskSize!, (value) {
    return _then(_self.copyWith(diskSize: value));
  });
}
}

// dart format on
