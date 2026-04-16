// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'secret_scanning2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SecretScanning2 {

@JsonKey(name: 'Status') Status2? get status;
/// Create a copy of SecretScanning2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecretScanning2CopyWith<SecretScanning2> get copyWith => _$SecretScanning2CopyWithImpl<SecretScanning2>(this as SecretScanning2, _$identity);

  /// Serializes this SecretScanning2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretScanning2&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'SecretScanning2(status: $status)';
}


}

/// @nodoc
abstract mixin class $SecretScanning2CopyWith<$Res>  {
  factory $SecretScanning2CopyWith(SecretScanning2 value, $Res Function(SecretScanning2) _then) = _$SecretScanning2CopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Status') Status2? status
});




}
/// @nodoc
class _$SecretScanning2CopyWithImpl<$Res>
    implements $SecretScanning2CopyWith<$Res> {
  _$SecretScanning2CopyWithImpl(this._self, this._then);

  final SecretScanning2 _self;
  final $Res Function(SecretScanning2) _then;

/// Create a copy of SecretScanning2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status2?,
  ));
}

}


/// Adds pattern-matching-related methods to [SecretScanning2].
extension SecretScanning2Patterns on SecretScanning2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SecretScanning2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SecretScanning2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SecretScanning2 value)  $default,){
final _that = this;
switch (_that) {
case _SecretScanning2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SecretScanning2 value)?  $default,){
final _that = this;
switch (_that) {
case _SecretScanning2() when $default != null:
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
case _SecretScanning2() when $default != null:
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
case _SecretScanning2():
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
case _SecretScanning2() when $default != null:
return $default(_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SecretScanning2 implements SecretScanning2 {
  const _SecretScanning2({@JsonKey(name: 'Status') this.status});
  factory _SecretScanning2.fromJson(Map<String, dynamic> json) => _$SecretScanning2FromJson(json);

@override@JsonKey(name: 'Status') final  Status2? status;

/// Create a copy of SecretScanning2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecretScanning2CopyWith<_SecretScanning2> get copyWith => __$SecretScanning2CopyWithImpl<_SecretScanning2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SecretScanning2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SecretScanning2&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'SecretScanning2(status: $status)';
}


}

/// @nodoc
abstract mixin class _$SecretScanning2CopyWith<$Res> implements $SecretScanning2CopyWith<$Res> {
  factory _$SecretScanning2CopyWith(_SecretScanning2 value, $Res Function(_SecretScanning2) _then) = __$SecretScanning2CopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Status') Status2? status
});




}
/// @nodoc
class __$SecretScanning2CopyWithImpl<$Res>
    implements _$SecretScanning2CopyWith<$Res> {
  __$SecretScanning2CopyWithImpl(this._self, this._then);

  final _SecretScanning2 _self;
  final $Res Function(_SecretScanning2) _then;

/// Create a copy of SecretScanning2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(_SecretScanning2(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status2?,
  ));
}


}

// dart format on
