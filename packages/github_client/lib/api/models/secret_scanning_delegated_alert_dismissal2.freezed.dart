// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'secret_scanning_delegated_alert_dismissal2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SecretScanningDelegatedAlertDismissal2 {

@JsonKey(name: 'Status') Status2? get status;
/// Create a copy of SecretScanningDelegatedAlertDismissal2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecretScanningDelegatedAlertDismissal2CopyWith<SecretScanningDelegatedAlertDismissal2> get copyWith => _$SecretScanningDelegatedAlertDismissal2CopyWithImpl<SecretScanningDelegatedAlertDismissal2>(this as SecretScanningDelegatedAlertDismissal2, _$identity);

  /// Serializes this SecretScanningDelegatedAlertDismissal2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretScanningDelegatedAlertDismissal2&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'SecretScanningDelegatedAlertDismissal2(status: $status)';
}


}

/// @nodoc
abstract mixin class $SecretScanningDelegatedAlertDismissal2CopyWith<$Res>  {
  factory $SecretScanningDelegatedAlertDismissal2CopyWith(SecretScanningDelegatedAlertDismissal2 value, $Res Function(SecretScanningDelegatedAlertDismissal2) _then) = _$SecretScanningDelegatedAlertDismissal2CopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Status') Status2? status
});




}
/// @nodoc
class _$SecretScanningDelegatedAlertDismissal2CopyWithImpl<$Res>
    implements $SecretScanningDelegatedAlertDismissal2CopyWith<$Res> {
  _$SecretScanningDelegatedAlertDismissal2CopyWithImpl(this._self, this._then);

  final SecretScanningDelegatedAlertDismissal2 _self;
  final $Res Function(SecretScanningDelegatedAlertDismissal2) _then;

/// Create a copy of SecretScanningDelegatedAlertDismissal2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status2?,
  ));
}

}


/// Adds pattern-matching-related methods to [SecretScanningDelegatedAlertDismissal2].
extension SecretScanningDelegatedAlertDismissal2Patterns on SecretScanningDelegatedAlertDismissal2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SecretScanningDelegatedAlertDismissal2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedAlertDismissal2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SecretScanningDelegatedAlertDismissal2 value)  $default,){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedAlertDismissal2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SecretScanningDelegatedAlertDismissal2 value)?  $default,){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedAlertDismissal2() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Status')  Status2? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SecretScanningDelegatedAlertDismissal2() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Status')  Status2? status)  $default,) {final _that = this;
switch (_that) {
case _SecretScanningDelegatedAlertDismissal2():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Status')  Status2? status)?  $default,) {final _that = this;
switch (_that) {
case _SecretScanningDelegatedAlertDismissal2() when $default != null:
return $default(_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SecretScanningDelegatedAlertDismissal2 implements SecretScanningDelegatedAlertDismissal2 {
  const _SecretScanningDelegatedAlertDismissal2({@JsonKey(name: 'Status') this.status});
  factory _SecretScanningDelegatedAlertDismissal2.fromJson(Map<String, dynamic> json) => _$SecretScanningDelegatedAlertDismissal2FromJson(json);

@override@JsonKey(name: 'Status') final  Status2? status;

/// Create a copy of SecretScanningDelegatedAlertDismissal2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecretScanningDelegatedAlertDismissal2CopyWith<_SecretScanningDelegatedAlertDismissal2> get copyWith => __$SecretScanningDelegatedAlertDismissal2CopyWithImpl<_SecretScanningDelegatedAlertDismissal2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SecretScanningDelegatedAlertDismissal2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SecretScanningDelegatedAlertDismissal2&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'SecretScanningDelegatedAlertDismissal2(status: $status)';
}


}

/// @nodoc
abstract mixin class _$SecretScanningDelegatedAlertDismissal2CopyWith<$Res> implements $SecretScanningDelegatedAlertDismissal2CopyWith<$Res> {
  factory _$SecretScanningDelegatedAlertDismissal2CopyWith(_SecretScanningDelegatedAlertDismissal2 value, $Res Function(_SecretScanningDelegatedAlertDismissal2) _then) = __$SecretScanningDelegatedAlertDismissal2CopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Status') Status2? status
});




}
/// @nodoc
class __$SecretScanningDelegatedAlertDismissal2CopyWithImpl<$Res>
    implements _$SecretScanningDelegatedAlertDismissal2CopyWith<$Res> {
  __$SecretScanningDelegatedAlertDismissal2CopyWithImpl(this._self, this._then);

  final _SecretScanningDelegatedAlertDismissal2 _self;
  final $Res Function(_SecretScanningDelegatedAlertDismissal2) _then;

/// Create a copy of SecretScanningDelegatedAlertDismissal2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(_SecretScanningDelegatedAlertDismissal2(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status2?,
  ));
}


}

// dart format on
