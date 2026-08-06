// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'claim_job_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClaimJobRequest {

 String? get vmName; String? get workerHost; int? get maxConcurrentJobs;
/// Create a copy of ClaimJobRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClaimJobRequestCopyWith<ClaimJobRequest> get copyWith => _$ClaimJobRequestCopyWithImpl<ClaimJobRequest>(this as ClaimJobRequest, _$identity);

  /// Serializes this ClaimJobRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaimJobRequest&&(identical(other.vmName, vmName) || other.vmName == vmName)&&(identical(other.workerHost, workerHost) || other.workerHost == workerHost)&&(identical(other.maxConcurrentJobs, maxConcurrentJobs) || other.maxConcurrentJobs == maxConcurrentJobs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vmName,workerHost,maxConcurrentJobs);

@override
String toString() {
  return 'ClaimJobRequest(vmName: $vmName, workerHost: $workerHost, maxConcurrentJobs: $maxConcurrentJobs)';
}


}

/// @nodoc
abstract mixin class $ClaimJobRequestCopyWith<$Res>  {
  factory $ClaimJobRequestCopyWith(ClaimJobRequest value, $Res Function(ClaimJobRequest) _then) = _$ClaimJobRequestCopyWithImpl;
@useResult
$Res call({
 String? vmName, String? workerHost, int? maxConcurrentJobs
});




}
/// @nodoc
class _$ClaimJobRequestCopyWithImpl<$Res>
    implements $ClaimJobRequestCopyWith<$Res> {
  _$ClaimJobRequestCopyWithImpl(this._self, this._then);

  final ClaimJobRequest _self;
  final $Res Function(ClaimJobRequest) _then;

/// Create a copy of ClaimJobRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vmName = freezed,Object? workerHost = freezed,Object? maxConcurrentJobs = freezed,}) {
  return _then(_self.copyWith(
vmName: freezed == vmName ? _self.vmName : vmName // ignore: cast_nullable_to_non_nullable
as String?,workerHost: freezed == workerHost ? _self.workerHost : workerHost // ignore: cast_nullable_to_non_nullable
as String?,maxConcurrentJobs: freezed == maxConcurrentJobs ? _self.maxConcurrentJobs : maxConcurrentJobs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ClaimJobRequest].
extension ClaimJobRequestPatterns on ClaimJobRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClaimJobRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClaimJobRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClaimJobRequest value)  $default,){
final _that = this;
switch (_that) {
case _ClaimJobRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClaimJobRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ClaimJobRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? vmName,  String? workerHost,  int? maxConcurrentJobs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClaimJobRequest() when $default != null:
return $default(_that.vmName,_that.workerHost,_that.maxConcurrentJobs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? vmName,  String? workerHost,  int? maxConcurrentJobs)  $default,) {final _that = this;
switch (_that) {
case _ClaimJobRequest():
return $default(_that.vmName,_that.workerHost,_that.maxConcurrentJobs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? vmName,  String? workerHost,  int? maxConcurrentJobs)?  $default,) {final _that = this;
switch (_that) {
case _ClaimJobRequest() when $default != null:
return $default(_that.vmName,_that.workerHost,_that.maxConcurrentJobs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClaimJobRequest implements ClaimJobRequest {
  const _ClaimJobRequest({this.vmName, this.workerHost, this.maxConcurrentJobs});
  factory _ClaimJobRequest.fromJson(Map<String, dynamic> json) => _$ClaimJobRequestFromJson(json);

@override final  String? vmName;
@override final  String? workerHost;
@override final  int? maxConcurrentJobs;

/// Create a copy of ClaimJobRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClaimJobRequestCopyWith<_ClaimJobRequest> get copyWith => __$ClaimJobRequestCopyWithImpl<_ClaimJobRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClaimJobRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClaimJobRequest&&(identical(other.vmName, vmName) || other.vmName == vmName)&&(identical(other.workerHost, workerHost) || other.workerHost == workerHost)&&(identical(other.maxConcurrentJobs, maxConcurrentJobs) || other.maxConcurrentJobs == maxConcurrentJobs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vmName,workerHost,maxConcurrentJobs);

@override
String toString() {
  return 'ClaimJobRequest(vmName: $vmName, workerHost: $workerHost, maxConcurrentJobs: $maxConcurrentJobs)';
}


}

/// @nodoc
abstract mixin class _$ClaimJobRequestCopyWith<$Res> implements $ClaimJobRequestCopyWith<$Res> {
  factory _$ClaimJobRequestCopyWith(_ClaimJobRequest value, $Res Function(_ClaimJobRequest) _then) = __$ClaimJobRequestCopyWithImpl;
@override @useResult
$Res call({
 String? vmName, String? workerHost, int? maxConcurrentJobs
});




}
/// @nodoc
class __$ClaimJobRequestCopyWithImpl<$Res>
    implements _$ClaimJobRequestCopyWith<$Res> {
  __$ClaimJobRequestCopyWithImpl(this._self, this._then);

  final _ClaimJobRequest _self;
  final $Res Function(_ClaimJobRequest) _then;

/// Create a copy of ClaimJobRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vmName = freezed,Object? workerHost = freezed,Object? maxConcurrentJobs = freezed,}) {
  return _then(_ClaimJobRequest(
vmName: freezed == vmName ? _self.vmName : vmName // ignore: cast_nullable_to_non_nullable
as String?,workerHost: freezed == workerHost ? _self.workerHost : workerHost // ignore: cast_nullable_to_non_nullable
as String?,maxConcurrentJobs: freezed == maxConcurrentJobs ? _self.maxConcurrentJobs : maxConcurrentJobs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
