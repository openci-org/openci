// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'advanced_security2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdvancedSecurity2 {

@JsonKey(name: 'Status') Status2? get status;
/// Create a copy of AdvancedSecurity2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdvancedSecurity2CopyWith<AdvancedSecurity2> get copyWith => _$AdvancedSecurity2CopyWithImpl<AdvancedSecurity2>(this as AdvancedSecurity2, _$identity);

  /// Serializes this AdvancedSecurity2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdvancedSecurity2&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'AdvancedSecurity2(status: $status)';
}


}

/// @nodoc
abstract mixin class $AdvancedSecurity2CopyWith<$Res>  {
  factory $AdvancedSecurity2CopyWith(AdvancedSecurity2 value, $Res Function(AdvancedSecurity2) _then) = _$AdvancedSecurity2CopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Status') Status2? status
});




}
/// @nodoc
class _$AdvancedSecurity2CopyWithImpl<$Res>
    implements $AdvancedSecurity2CopyWith<$Res> {
  _$AdvancedSecurity2CopyWithImpl(this._self, this._then);

  final AdvancedSecurity2 _self;
  final $Res Function(AdvancedSecurity2) _then;

/// Create a copy of AdvancedSecurity2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status2?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdvancedSecurity2].
extension AdvancedSecurity2Patterns on AdvancedSecurity2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdvancedSecurity2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdvancedSecurity2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdvancedSecurity2 value)  $default,){
final _that = this;
switch (_that) {
case _AdvancedSecurity2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdvancedSecurity2 value)?  $default,){
final _that = this;
switch (_that) {
case _AdvancedSecurity2() when $default != null:
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
case _AdvancedSecurity2() when $default != null:
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
case _AdvancedSecurity2():
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
case _AdvancedSecurity2() when $default != null:
return $default(_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdvancedSecurity2 implements AdvancedSecurity2 {
  const _AdvancedSecurity2({@JsonKey(name: 'Status') this.status});
  factory _AdvancedSecurity2.fromJson(Map<String, dynamic> json) => _$AdvancedSecurity2FromJson(json);

@override@JsonKey(name: 'Status') final  Status2? status;

/// Create a copy of AdvancedSecurity2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdvancedSecurity2CopyWith<_AdvancedSecurity2> get copyWith => __$AdvancedSecurity2CopyWithImpl<_AdvancedSecurity2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdvancedSecurity2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdvancedSecurity2&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'AdvancedSecurity2(status: $status)';
}


}

/// @nodoc
abstract mixin class _$AdvancedSecurity2CopyWith<$Res> implements $AdvancedSecurity2CopyWith<$Res> {
  factory _$AdvancedSecurity2CopyWith(_AdvancedSecurity2 value, $Res Function(_AdvancedSecurity2) _then) = __$AdvancedSecurity2CopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Status') Status2? status
});




}
/// @nodoc
class __$AdvancedSecurity2CopyWithImpl<$Res>
    implements _$AdvancedSecurity2CopyWith<$Res> {
  __$AdvancedSecurity2CopyWithImpl(this._self, this._then);

  final _AdvancedSecurity2 _self;
  final $Res Function(_AdvancedSecurity2) _then;

/// Create a copy of AdvancedSecurity2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(_AdvancedSecurity2(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status2?,
  ));
}


}

// dart format on
