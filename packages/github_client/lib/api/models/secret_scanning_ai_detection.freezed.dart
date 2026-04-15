// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'secret_scanning_ai_detection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SecretScanningAiDetection {

/// Can be `enabled` or `disabled`.
@JsonKey(name: 'Status') String? get status;
/// Create a copy of SecretScanningAiDetection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecretScanningAiDetectionCopyWith<SecretScanningAiDetection> get copyWith => _$SecretScanningAiDetectionCopyWithImpl<SecretScanningAiDetection>(this as SecretScanningAiDetection, _$identity);

  /// Serializes this SecretScanningAiDetection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretScanningAiDetection&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'SecretScanningAiDetection(status: $status)';
}


}

/// @nodoc
abstract mixin class $SecretScanningAiDetectionCopyWith<$Res>  {
  factory $SecretScanningAiDetectionCopyWith(SecretScanningAiDetection value, $Res Function(SecretScanningAiDetection) _then) = _$SecretScanningAiDetectionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Status') String? status
});




}
/// @nodoc
class _$SecretScanningAiDetectionCopyWithImpl<$Res>
    implements $SecretScanningAiDetectionCopyWith<$Res> {
  _$SecretScanningAiDetectionCopyWithImpl(this._self, this._then);

  final SecretScanningAiDetection _self;
  final $Res Function(SecretScanningAiDetection) _then;

/// Create a copy of SecretScanningAiDetection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SecretScanningAiDetection].
extension SecretScanningAiDetectionPatterns on SecretScanningAiDetection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SecretScanningAiDetection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SecretScanningAiDetection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SecretScanningAiDetection value)  $default,){
final _that = this;
switch (_that) {
case _SecretScanningAiDetection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SecretScanningAiDetection value)?  $default,){
final _that = this;
switch (_that) {
case _SecretScanningAiDetection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Status')  String? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SecretScanningAiDetection() when $default != null:
return $default(_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Status')  String? status)  $default,) {final _that = this;
switch (_that) {
case _SecretScanningAiDetection():
return $default(_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Status')  String? status)?  $default,) {final _that = this;
switch (_that) {
case _SecretScanningAiDetection() when $default != null:
return $default(_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SecretScanningAiDetection implements SecretScanningAiDetection {
  const _SecretScanningAiDetection({@JsonKey(name: 'Status') this.status});
  factory _SecretScanningAiDetection.fromJson(Map<String, dynamic> json) => _$SecretScanningAiDetectionFromJson(json);

/// Can be `enabled` or `disabled`.
@override@JsonKey(name: 'Status') final  String? status;

/// Create a copy of SecretScanningAiDetection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecretScanningAiDetectionCopyWith<_SecretScanningAiDetection> get copyWith => __$SecretScanningAiDetectionCopyWithImpl<_SecretScanningAiDetection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SecretScanningAiDetectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SecretScanningAiDetection&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'SecretScanningAiDetection(status: $status)';
}


}

/// @nodoc
abstract mixin class _$SecretScanningAiDetectionCopyWith<$Res> implements $SecretScanningAiDetectionCopyWith<$Res> {
  factory _$SecretScanningAiDetectionCopyWith(_SecretScanningAiDetection value, $Res Function(_SecretScanningAiDetection) _then) = __$SecretScanningAiDetectionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Status') String? status
});




}
/// @nodoc
class __$SecretScanningAiDetectionCopyWithImpl<$Res>
    implements _$SecretScanningAiDetectionCopyWith<$Res> {
  __$SecretScanningAiDetectionCopyWithImpl(this._self, this._then);

  final _SecretScanningAiDetection _self;
  final $Res Function(_SecretScanningAiDetection) _then;

/// Create a copy of SecretScanningAiDetection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(_SecretScanningAiDetection(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
