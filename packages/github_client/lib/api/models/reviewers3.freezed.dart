// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reviewers3.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Reviewers3 {

/// The ID of the Team or role selected as a bypass reviewer
@JsonKey(name: 'reviewer_id') int get reviewerId;/// The type of the bypass reviewer
@JsonKey(name: 'reviewer_type') ReviewerType get reviewerType;/// The bypass mode for the reviewer
 Mode get mode;
/// Create a copy of Reviewers3
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Reviewers3CopyWith<Reviewers3> get copyWith => _$Reviewers3CopyWithImpl<Reviewers3>(this as Reviewers3, _$identity);

  /// Serializes this Reviewers3 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reviewers3&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.reviewerType, reviewerType) || other.reviewerType == reviewerType)&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reviewerId,reviewerType,mode);

@override
String toString() {
  return 'Reviewers3(reviewerId: $reviewerId, reviewerType: $reviewerType, mode: $mode)';
}


}

/// @nodoc
abstract mixin class $Reviewers3CopyWith<$Res>  {
  factory $Reviewers3CopyWith(Reviewers3 value, $Res Function(Reviewers3) _then) = _$Reviewers3CopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'reviewer_id') int reviewerId,@JsonKey(name: 'reviewer_type') ReviewerType reviewerType, Mode mode
});




}
/// @nodoc
class _$Reviewers3CopyWithImpl<$Res>
    implements $Reviewers3CopyWith<$Res> {
  _$Reviewers3CopyWithImpl(this._self, this._then);

  final Reviewers3 _self;
  final $Res Function(Reviewers3) _then;

/// Create a copy of Reviewers3
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reviewerId = null,Object? reviewerType = null,Object? mode = null,}) {
  return _then(_self.copyWith(
reviewerId: null == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as int,reviewerType: null == reviewerType ? _self.reviewerType : reviewerType // ignore: cast_nullable_to_non_nullable
as ReviewerType,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as Mode,
  ));
}

}


/// Adds pattern-matching-related methods to [Reviewers3].
extension Reviewers3Patterns on Reviewers3 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reviewers3 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reviewers3() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reviewers3 value)  $default,){
final _that = this;
switch (_that) {
case _Reviewers3():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reviewers3 value)?  $default,){
final _that = this;
switch (_that) {
case _Reviewers3() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'reviewer_id')  int reviewerId, @JsonKey(name: 'reviewer_type')  ReviewerType reviewerType,  Mode mode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reviewers3() when $default != null:
return $default(_that.reviewerId,_that.reviewerType,_that.mode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'reviewer_id')  int reviewerId, @JsonKey(name: 'reviewer_type')  ReviewerType reviewerType,  Mode mode)  $default,) {final _that = this;
switch (_that) {
case _Reviewers3():
return $default(_that.reviewerId,_that.reviewerType,_that.mode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'reviewer_id')  int reviewerId, @JsonKey(name: 'reviewer_type')  ReviewerType reviewerType,  Mode mode)?  $default,) {final _that = this;
switch (_that) {
case _Reviewers3() when $default != null:
return $default(_that.reviewerId,_that.reviewerType,_that.mode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reviewers3 implements Reviewers3 {
  const _Reviewers3({@JsonKey(name: 'reviewer_id') required this.reviewerId, @JsonKey(name: 'reviewer_type') required this.reviewerType, this.mode = Mode.always});
  factory _Reviewers3.fromJson(Map<String, dynamic> json) => _$Reviewers3FromJson(json);

/// The ID of the Team or role selected as a bypass reviewer
@override@JsonKey(name: 'reviewer_id') final  int reviewerId;
/// The type of the bypass reviewer
@override@JsonKey(name: 'reviewer_type') final  ReviewerType reviewerType;
/// The bypass mode for the reviewer
@override@JsonKey() final  Mode mode;

/// Create a copy of Reviewers3
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Reviewers3CopyWith<_Reviewers3> get copyWith => __$Reviewers3CopyWithImpl<_Reviewers3>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Reviewers3ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reviewers3&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.reviewerType, reviewerType) || other.reviewerType == reviewerType)&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reviewerId,reviewerType,mode);

@override
String toString() {
  return 'Reviewers3(reviewerId: $reviewerId, reviewerType: $reviewerType, mode: $mode)';
}


}

/// @nodoc
abstract mixin class _$Reviewers3CopyWith<$Res> implements $Reviewers3CopyWith<$Res> {
  factory _$Reviewers3CopyWith(_Reviewers3 value, $Res Function(_Reviewers3) _then) = __$Reviewers3CopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'reviewer_id') int reviewerId,@JsonKey(name: 'reviewer_type') ReviewerType reviewerType, Mode mode
});




}
/// @nodoc
class __$Reviewers3CopyWithImpl<$Res>
    implements _$Reviewers3CopyWith<$Res> {
  __$Reviewers3CopyWithImpl(this._self, this._then);

  final _Reviewers3 _self;
  final $Res Function(_Reviewers3) _then;

/// Create a copy of Reviewers3
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reviewerId = null,Object? reviewerType = null,Object? mode = null,}) {
  return _then(_Reviewers3(
reviewerId: null == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as int,reviewerType: null == reviewerType ? _self.reviewerType : reviewerType // ignore: cast_nullable_to_non_nullable
as ReviewerType,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as Mode,
  ));
}


}

// dart format on
