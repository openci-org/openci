// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'secret_scanning_non_provider_patterns.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SecretScanningNonProviderPatterns {

/// Can be `enabled` or `disabled`.
@JsonKey(name: 'Status') String? get status;
/// Create a copy of SecretScanningNonProviderPatterns
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecretScanningNonProviderPatternsCopyWith<SecretScanningNonProviderPatterns> get copyWith => _$SecretScanningNonProviderPatternsCopyWithImpl<SecretScanningNonProviderPatterns>(this as SecretScanningNonProviderPatterns, _$identity);

  /// Serializes this SecretScanningNonProviderPatterns to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretScanningNonProviderPatterns&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'SecretScanningNonProviderPatterns(status: $status)';
}


}

/// @nodoc
abstract mixin class $SecretScanningNonProviderPatternsCopyWith<$Res>  {
  factory $SecretScanningNonProviderPatternsCopyWith(SecretScanningNonProviderPatterns value, $Res Function(SecretScanningNonProviderPatterns) _then) = _$SecretScanningNonProviderPatternsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Status') String? status
});




}
/// @nodoc
class _$SecretScanningNonProviderPatternsCopyWithImpl<$Res>
    implements $SecretScanningNonProviderPatternsCopyWith<$Res> {
  _$SecretScanningNonProviderPatternsCopyWithImpl(this._self, this._then);

  final SecretScanningNonProviderPatterns _self;
  final $Res Function(SecretScanningNonProviderPatterns) _then;

/// Create a copy of SecretScanningNonProviderPatterns
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SecretScanningNonProviderPatterns].
extension SecretScanningNonProviderPatternsPatterns on SecretScanningNonProviderPatterns {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SecretScanningNonProviderPatterns value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SecretScanningNonProviderPatterns() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SecretScanningNonProviderPatterns value)  $default,){
final _that = this;
switch (_that) {
case _SecretScanningNonProviderPatterns():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SecretScanningNonProviderPatterns value)?  $default,){
final _that = this;
switch (_that) {
case _SecretScanningNonProviderPatterns() when $default != null:
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
case _SecretScanningNonProviderPatterns() when $default != null:
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
case _SecretScanningNonProviderPatterns():
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
case _SecretScanningNonProviderPatterns() when $default != null:
return $default(_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SecretScanningNonProviderPatterns implements SecretScanningNonProviderPatterns {
  const _SecretScanningNonProviderPatterns({@JsonKey(name: 'Status') this.status});
  factory _SecretScanningNonProviderPatterns.fromJson(Map<String, dynamic> json) => _$SecretScanningNonProviderPatternsFromJson(json);

/// Can be `enabled` or `disabled`.
@override@JsonKey(name: 'Status') final  String? status;

/// Create a copy of SecretScanningNonProviderPatterns
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecretScanningNonProviderPatternsCopyWith<_SecretScanningNonProviderPatterns> get copyWith => __$SecretScanningNonProviderPatternsCopyWithImpl<_SecretScanningNonProviderPatterns>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SecretScanningNonProviderPatternsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SecretScanningNonProviderPatterns&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'SecretScanningNonProviderPatterns(status: $status)';
}


}

/// @nodoc
abstract mixin class _$SecretScanningNonProviderPatternsCopyWith<$Res> implements $SecretScanningNonProviderPatternsCopyWith<$Res> {
  factory _$SecretScanningNonProviderPatternsCopyWith(_SecretScanningNonProviderPatterns value, $Res Function(_SecretScanningNonProviderPatterns) _then) = __$SecretScanningNonProviderPatternsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Status') String? status
});




}
/// @nodoc
class __$SecretScanningNonProviderPatternsCopyWithImpl<$Res>
    implements _$SecretScanningNonProviderPatternsCopyWith<$Res> {
  __$SecretScanningNonProviderPatternsCopyWithImpl(this._self, this._then);

  final _SecretScanningNonProviderPatterns _self;
  final $Res Function(_SecretScanningNonProviderPatterns) _then;

/// Create a copy of SecretScanningNonProviderPatterns
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(_SecretScanningNonProviderPatterns(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
