// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'advanced_security.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdvancedSecurity {

/// Can be `enabled` or `disabled`.
@JsonKey(name: 'Status') String? get status;
/// Create a copy of AdvancedSecurity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdvancedSecurityCopyWith<AdvancedSecurity> get copyWith => _$AdvancedSecurityCopyWithImpl<AdvancedSecurity>(this as AdvancedSecurity, _$identity);

  /// Serializes this AdvancedSecurity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdvancedSecurity&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'AdvancedSecurity(status: $status)';
}


}

/// @nodoc
abstract mixin class $AdvancedSecurityCopyWith<$Res>  {
  factory $AdvancedSecurityCopyWith(AdvancedSecurity value, $Res Function(AdvancedSecurity) _then) = _$AdvancedSecurityCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Status') String? status
});




}
/// @nodoc
class _$AdvancedSecurityCopyWithImpl<$Res>
    implements $AdvancedSecurityCopyWith<$Res> {
  _$AdvancedSecurityCopyWithImpl(this._self, this._then);

  final AdvancedSecurity _self;
  final $Res Function(AdvancedSecurity) _then;

/// Create a copy of AdvancedSecurity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdvancedSecurity].
extension AdvancedSecurityPatterns on AdvancedSecurity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdvancedSecurity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdvancedSecurity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdvancedSecurity value)  $default,){
final _that = this;
switch (_that) {
case _AdvancedSecurity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdvancedSecurity value)?  $default,){
final _that = this;
switch (_that) {
case _AdvancedSecurity() when $default != null:
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
case _AdvancedSecurity() when $default != null:
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
case _AdvancedSecurity():
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
case _AdvancedSecurity() when $default != null:
return $default(_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdvancedSecurity implements AdvancedSecurity {
  const _AdvancedSecurity({@JsonKey(name: 'Status') this.status});
  factory _AdvancedSecurity.fromJson(Map<String, dynamic> json) => _$AdvancedSecurityFromJson(json);

/// Can be `enabled` or `disabled`.
@override@JsonKey(name: 'Status') final  String? status;

/// Create a copy of AdvancedSecurity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdvancedSecurityCopyWith<_AdvancedSecurity> get copyWith => __$AdvancedSecurityCopyWithImpl<_AdvancedSecurity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdvancedSecurityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdvancedSecurity&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'AdvancedSecurity(status: $status)';
}


}

/// @nodoc
abstract mixin class _$AdvancedSecurityCopyWith<$Res> implements $AdvancedSecurityCopyWith<$Res> {
  factory _$AdvancedSecurityCopyWith(_AdvancedSecurity value, $Res Function(_AdvancedSecurity) _then) = __$AdvancedSecurityCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Status') String? status
});




}
/// @nodoc
class __$AdvancedSecurityCopyWithImpl<$Res>
    implements _$AdvancedSecurityCopyWith<$Res> {
  __$AdvancedSecurityCopyWithImpl(this._self, this._then);

  final _AdvancedSecurity _self;
  final $Res Function(_AdvancedSecurity) _then;

/// Create a copy of AdvancedSecurity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(_AdvancedSecurity(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
