// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'secret_scanning_delegated_alert_dismissal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SecretScanningDelegatedAlertDismissal {

/// Can be `enabled` or `disabled`.
@JsonKey(name: 'Status') String? get status;
/// Create a copy of SecretScanningDelegatedAlertDismissal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecretScanningDelegatedAlertDismissalCopyWith<SecretScanningDelegatedAlertDismissal> get copyWith => _$SecretScanningDelegatedAlertDismissalCopyWithImpl<SecretScanningDelegatedAlertDismissal>(this as SecretScanningDelegatedAlertDismissal, _$identity);

  /// Serializes this SecretScanningDelegatedAlertDismissal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretScanningDelegatedAlertDismissal&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'SecretScanningDelegatedAlertDismissal(status: $status)';
}


}

/// @nodoc
abstract mixin class $SecretScanningDelegatedAlertDismissalCopyWith<$Res>  {
  factory $SecretScanningDelegatedAlertDismissalCopyWith(SecretScanningDelegatedAlertDismissal value, $Res Function(SecretScanningDelegatedAlertDismissal) _then) = _$SecretScanningDelegatedAlertDismissalCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Status') String? status
});




}
/// @nodoc
class _$SecretScanningDelegatedAlertDismissalCopyWithImpl<$Res>
    implements $SecretScanningDelegatedAlertDismissalCopyWith<$Res> {
  _$SecretScanningDelegatedAlertDismissalCopyWithImpl(this._self, this._then);

  final SecretScanningDelegatedAlertDismissal _self;
  final $Res Function(SecretScanningDelegatedAlertDismissal) _then;

/// Create a copy of SecretScanningDelegatedAlertDismissal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SecretScanningDelegatedAlertDismissal].
extension SecretScanningDelegatedAlertDismissalPatterns on SecretScanningDelegatedAlertDismissal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SecretScanningDelegatedAlertDismissal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedAlertDismissal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SecretScanningDelegatedAlertDismissal value)  $default,){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedAlertDismissal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SecretScanningDelegatedAlertDismissal value)?  $default,){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedAlertDismissal() when $default != null:
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
case _SecretScanningDelegatedAlertDismissal() when $default != null:
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
case _SecretScanningDelegatedAlertDismissal():
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
case _SecretScanningDelegatedAlertDismissal() when $default != null:
return $default(_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SecretScanningDelegatedAlertDismissal implements SecretScanningDelegatedAlertDismissal {
  const _SecretScanningDelegatedAlertDismissal({@JsonKey(name: 'Status') this.status});
  factory _SecretScanningDelegatedAlertDismissal.fromJson(Map<String, dynamic> json) => _$SecretScanningDelegatedAlertDismissalFromJson(json);

/// Can be `enabled` or `disabled`.
@override@JsonKey(name: 'Status') final  String? status;

/// Create a copy of SecretScanningDelegatedAlertDismissal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecretScanningDelegatedAlertDismissalCopyWith<_SecretScanningDelegatedAlertDismissal> get copyWith => __$SecretScanningDelegatedAlertDismissalCopyWithImpl<_SecretScanningDelegatedAlertDismissal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SecretScanningDelegatedAlertDismissalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SecretScanningDelegatedAlertDismissal&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'SecretScanningDelegatedAlertDismissal(status: $status)';
}


}

/// @nodoc
abstract mixin class _$SecretScanningDelegatedAlertDismissalCopyWith<$Res> implements $SecretScanningDelegatedAlertDismissalCopyWith<$Res> {
  factory _$SecretScanningDelegatedAlertDismissalCopyWith(_SecretScanningDelegatedAlertDismissal value, $Res Function(_SecretScanningDelegatedAlertDismissal) _then) = __$SecretScanningDelegatedAlertDismissalCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Status') String? status
});




}
/// @nodoc
class __$SecretScanningDelegatedAlertDismissalCopyWithImpl<$Res>
    implements _$SecretScanningDelegatedAlertDismissalCopyWith<$Res> {
  __$SecretScanningDelegatedAlertDismissalCopyWithImpl(this._self, this._then);

  final _SecretScanningDelegatedAlertDismissal _self;
  final $Res Function(_SecretScanningDelegatedAlertDismissal) _then;

/// Create a copy of SecretScanningDelegatedAlertDismissal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(_SecretScanningDelegatedAlertDismissal(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
