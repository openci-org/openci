// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'secret_scanning_delegated_bypass_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SecretScanningDelegatedBypassOptions {

/// The bypass reviewers for secret scanning delegated bypass.
/// If you omit this field, the existing set of reviewers is unchanged.
 List<Reviewers>? get reviewers;
/// Create a copy of SecretScanningDelegatedBypassOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecretScanningDelegatedBypassOptionsCopyWith<SecretScanningDelegatedBypassOptions> get copyWith => _$SecretScanningDelegatedBypassOptionsCopyWithImpl<SecretScanningDelegatedBypassOptions>(this as SecretScanningDelegatedBypassOptions, _$identity);

  /// Serializes this SecretScanningDelegatedBypassOptions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecretScanningDelegatedBypassOptions&&const DeepCollectionEquality().equals(other.reviewers, reviewers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(reviewers));

@override
String toString() {
  return 'SecretScanningDelegatedBypassOptions(reviewers: $reviewers)';
}


}

/// @nodoc
abstract mixin class $SecretScanningDelegatedBypassOptionsCopyWith<$Res>  {
  factory $SecretScanningDelegatedBypassOptionsCopyWith(SecretScanningDelegatedBypassOptions value, $Res Function(SecretScanningDelegatedBypassOptions) _then) = _$SecretScanningDelegatedBypassOptionsCopyWithImpl;
@useResult
$Res call({
 List<Reviewers>? reviewers
});




}
/// @nodoc
class _$SecretScanningDelegatedBypassOptionsCopyWithImpl<$Res>
    implements $SecretScanningDelegatedBypassOptionsCopyWith<$Res> {
  _$SecretScanningDelegatedBypassOptionsCopyWithImpl(this._self, this._then);

  final SecretScanningDelegatedBypassOptions _self;
  final $Res Function(SecretScanningDelegatedBypassOptions) _then;

/// Create a copy of SecretScanningDelegatedBypassOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reviewers = freezed,}) {
  return _then(_self.copyWith(
reviewers: freezed == reviewers ? _self.reviewers : reviewers // ignore: cast_nullable_to_non_nullable
as List<Reviewers>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SecretScanningDelegatedBypassOptions].
extension SecretScanningDelegatedBypassOptionsPatterns on SecretScanningDelegatedBypassOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SecretScanningDelegatedBypassOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SecretScanningDelegatedBypassOptions value)  $default,){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SecretScanningDelegatedBypassOptions value)?  $default,){
final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Reviewers>? reviewers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Reviewers>? reviewers)  $default,) {final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Reviewers>? reviewers)?  $default,) {final _that = this;
switch (_that) {
case _SecretScanningDelegatedBypassOptions() when $default != null:
return $default(_that.reviewers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SecretScanningDelegatedBypassOptions implements SecretScanningDelegatedBypassOptions {
  const _SecretScanningDelegatedBypassOptions({final  List<Reviewers>? reviewers}): _reviewers = reviewers;
  factory _SecretScanningDelegatedBypassOptions.fromJson(Map<String, dynamic> json) => _$SecretScanningDelegatedBypassOptionsFromJson(json);

/// The bypass reviewers for secret scanning delegated bypass.
/// If you omit this field, the existing set of reviewers is unchanged.
 final  List<Reviewers>? _reviewers;
/// The bypass reviewers for secret scanning delegated bypass.
/// If you omit this field, the existing set of reviewers is unchanged.
@override List<Reviewers>? get reviewers {
  final value = _reviewers;
  if (value == null) return null;
  if (_reviewers is EqualUnmodifiableListView) return _reviewers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SecretScanningDelegatedBypassOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecretScanningDelegatedBypassOptionsCopyWith<_SecretScanningDelegatedBypassOptions> get copyWith => __$SecretScanningDelegatedBypassOptionsCopyWithImpl<_SecretScanningDelegatedBypassOptions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SecretScanningDelegatedBypassOptionsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SecretScanningDelegatedBypassOptions&&const DeepCollectionEquality().equals(other._reviewers, _reviewers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_reviewers));

@override
String toString() {
  return 'SecretScanningDelegatedBypassOptions(reviewers: $reviewers)';
}


}

/// @nodoc
abstract mixin class _$SecretScanningDelegatedBypassOptionsCopyWith<$Res> implements $SecretScanningDelegatedBypassOptionsCopyWith<$Res> {
  factory _$SecretScanningDelegatedBypassOptionsCopyWith(_SecretScanningDelegatedBypassOptions value, $Res Function(_SecretScanningDelegatedBypassOptions) _then) = __$SecretScanningDelegatedBypassOptionsCopyWithImpl;
@override @useResult
$Res call({
 List<Reviewers>? reviewers
});




}
/// @nodoc
class __$SecretScanningDelegatedBypassOptionsCopyWithImpl<$Res>
    implements _$SecretScanningDelegatedBypassOptionsCopyWith<$Res> {
  __$SecretScanningDelegatedBypassOptionsCopyWithImpl(this._self, this._then);

  final _SecretScanningDelegatedBypassOptions _self;
  final $Res Function(_SecretScanningDelegatedBypassOptions) _then;

/// Create a copy of SecretScanningDelegatedBypassOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reviewers = freezed,}) {
  return _then(_SecretScanningDelegatedBypassOptions(
reviewers: freezed == reviewers ? _self._reviewers : reviewers // ignore: cast_nullable_to_non_nullable
as List<Reviewers>?,
  ));
}


}

// dart format on
