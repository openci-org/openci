// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'secret_scanning_delegated_bypass_options3.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SecretScanningDelegatedBypassOptions3 {

/// The bypass reviewers for secret scanning delegated bypass
 List<Reviewers3>? get reviewers;
/// Create a copy of SecretScanningDelegatedBypassOptions3
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecretScanningDelegatedBypassOptions3CopyWith<SecretScanningDelegatedBypassOptions3> get copyWith => _$SecretScanningDelegatedBypassOptions3CopyWithImpl<SecretScanningDelegatedBypassOptions3>(this as SecretScanningDelegatedBypassOptions3, _$identity);

  /// Serializes this SecretScanningDelegatedBypassOptions3 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretScanningDelegatedBypassOptions3&&const DeepCollectionEquality().equals(other.reviewers, reviewers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(reviewers));

@override
String toString() {
  return 'SecretScanningDelegatedBypassOptions3(reviewers: $reviewers)';
}


}

/// @nodoc
abstract mixin class $SecretScanningDelegatedBypassOptions3CopyWith<$Res>  {
  factory $SecretScanningDelegatedBypassOptions3CopyWith(SecretScanningDelegatedBypassOptions3 value, $Res Function(SecretScanningDelegatedBypassOptions3) _then) = _$SecretScanningDelegatedBypassOptions3CopyWithImpl;
@useResult
$Res call({
 List<Reviewers3>? reviewers
});




}
/// @nodoc
class _$SecretScanningDelegatedBypassOptions3CopyWithImpl<$Res>
    implements $SecretScanningDelegatedBypassOptions3CopyWith<$Res> {
  _$SecretScanningDelegatedBypassOptions3CopyWithImpl(this._self, this._then);

  final SecretScanningDelegatedBypassOptions3 _self;
  final $Res Function(SecretScanningDelegatedBypassOptions3) _then;

/// Create a copy of SecretScanningDelegatedBypassOptions3
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reviewers = freezed,}) {
  return _then(_self.copyWith(
reviewers: freezed == reviewers ? _self.reviewers : reviewers // ignore: cast_nullable_to_non_nullable
as List<Reviewers3>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SecretScanningDelegatedBypassOptions3].
extension SecretScanningDelegatedBypassOptions3Patterns on SecretScanningDelegatedBypassOptions3 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SecretScanningDelegatedBypassOptions3 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions3() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SecretScanningDelegatedBypassOptions3 value)  $default,){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions3():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SecretScanningDelegatedBypassOptions3 value)?  $default,){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions3() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Reviewers3>? reviewers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions3() when $default != null:
return $default(_that.reviewers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Reviewers3>? reviewers)  $default,) {final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions3():
return $default(_that.reviewers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Reviewers3>? reviewers)?  $default,) {final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions3() when $default != null:
return $default(_that.reviewers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SecretScanningDelegatedBypassOptions3 implements SecretScanningDelegatedBypassOptions3 {
  const _SecretScanningDelegatedBypassOptions3({final  List<Reviewers3>? reviewers}): _reviewers = reviewers;
  factory _SecretScanningDelegatedBypassOptions3.fromJson(Map<String, dynamic> json) => _$SecretScanningDelegatedBypassOptions3FromJson(json);

/// The bypass reviewers for secret scanning delegated bypass
 final  List<Reviewers3>? _reviewers;
/// The bypass reviewers for secret scanning delegated bypass
@override List<Reviewers3>? get reviewers {
  final value = _reviewers;
  if (value == null) return null;
  if (_reviewers is EqualUnmodifiableListView) return _reviewers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SecretScanningDelegatedBypassOptions3
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecretScanningDelegatedBypassOptions3CopyWith<_SecretScanningDelegatedBypassOptions3> get copyWith => __$SecretScanningDelegatedBypassOptions3CopyWithImpl<_SecretScanningDelegatedBypassOptions3>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SecretScanningDelegatedBypassOptions3ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SecretScanningDelegatedBypassOptions3&&const DeepCollectionEquality().equals(other._reviewers, _reviewers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_reviewers));

@override
String toString() {
  return 'SecretScanningDelegatedBypassOptions3(reviewers: $reviewers)';
}


}

/// @nodoc
abstract mixin class _$SecretScanningDelegatedBypassOptions3CopyWith<$Res> implements $SecretScanningDelegatedBypassOptions3CopyWith<$Res> {
  factory _$SecretScanningDelegatedBypassOptions3CopyWith(_SecretScanningDelegatedBypassOptions3 value, $Res Function(_SecretScanningDelegatedBypassOptions3) _then) = __$SecretScanningDelegatedBypassOptions3CopyWithImpl;
@override @useResult
$Res call({
 List<Reviewers3>? reviewers
});




}
/// @nodoc
class __$SecretScanningDelegatedBypassOptions3CopyWithImpl<$Res>
    implements _$SecretScanningDelegatedBypassOptions3CopyWith<$Res> {
  __$SecretScanningDelegatedBypassOptions3CopyWithImpl(this._self, this._then);

  final _SecretScanningDelegatedBypassOptions3 _self;
  final $Res Function(_SecretScanningDelegatedBypassOptions3) _then;

/// Create a copy of SecretScanningDelegatedBypassOptions3
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reviewers = freezed,}) {
  return _then(_SecretScanningDelegatedBypassOptions3(
reviewers: freezed == reviewers ? _self._reviewers : reviewers // ignore: cast_nullable_to_non_nullable
as List<Reviewers3>?,
  ));
}


}

// dart format on
