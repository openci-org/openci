// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reviewers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Reviewers {

/// The ID of the Team or role selected as a bypass reviewer
@JsonKey(name: 'reviewer_id') int get reviewerId;/// The type of the bypass reviewer
@JsonKey(name: 'reviewer_type') ReviewerType get reviewerType;/// The bypass mode for the reviewer
 Mode get mode;
/// Create a copy of Reviewers
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewersCopyWith<Reviewers> get copyWith => _$ReviewersCopyWithImpl<Reviewers>(this as Reviewers, _$identity);

  /// Serializes this Reviewers to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reviewers&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.reviewerType, reviewerType) || other.reviewerType == reviewerType)&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reviewerId,reviewerType,mode);

@override
String toString() {
  return 'Reviewers(reviewerId: $reviewerId, reviewerType: $reviewerType, mode: $mode)';
}


}

/// @nodoc
abstract mixin class $ReviewersCopyWith<$Res>  {
  factory $ReviewersCopyWith(Reviewers value, $Res Function(Reviewers) _then) = _$ReviewersCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'reviewer_id') int reviewerId,@JsonKey(name: 'reviewer_type') ReviewerType reviewerType, Mode mode
});




}
/// @nodoc
class _$ReviewersCopyWithImpl<$Res>
    implements $ReviewersCopyWith<$Res> {
  _$ReviewersCopyWithImpl(this._self, this._then);

  final Reviewers _self;
  final $Res Function(Reviewers) _then;

/// Create a copy of Reviewers
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


/// Adds pattern-matching-related methods to [Reviewers].
extension ReviewersPatterns on Reviewers {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reviewers value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reviewers() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reviewers value)  $default,){
final _that = this;
switch (_that) {
case _Reviewers():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reviewers value)?  $default,){
final _that = this;
switch (_that) {
case _Reviewers() when $default != null:
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
case _Reviewers() when $default != null:
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
case _Reviewers():
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
case _Reviewers() when $default != null:
return $default(_that.reviewerId,_that.reviewerType,_that.mode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reviewers implements Reviewers {
  const _Reviewers({@JsonKey(name: 'reviewer_id') required this.reviewerId, @JsonKey(name: 'reviewer_type') required this.reviewerType, this.mode = Mode.always});
  factory _Reviewers.fromJson(Map<String, dynamic> json) => _$ReviewersFromJson(json);

/// The ID of the Team or role selected as a bypass reviewer
@override@JsonKey(name: 'reviewer_id') final  int reviewerId;
/// The type of the bypass reviewer
@override@JsonKey(name: 'reviewer_type') final  ReviewerType reviewerType;
/// The bypass mode for the reviewer
@override@JsonKey() final  Mode mode;

/// Create a copy of Reviewers
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewersCopyWith<_Reviewers> get copyWith => __$ReviewersCopyWithImpl<_Reviewers>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewersToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reviewers&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.reviewerType, reviewerType) || other.reviewerType == reviewerType)&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reviewerId,reviewerType,mode);

@override
String toString() {
  return 'Reviewers(reviewerId: $reviewerId, reviewerType: $reviewerType, mode: $mode)';
}


}

/// @nodoc
abstract mixin class _$ReviewersCopyWith<$Res> implements $ReviewersCopyWith<$Res> {
  factory _$ReviewersCopyWith(_Reviewers value, $Res Function(_Reviewers) _then) = __$ReviewersCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'reviewer_id') int reviewerId,@JsonKey(name: 'reviewer_type') ReviewerType reviewerType, Mode mode
});




}
/// @nodoc
class __$ReviewersCopyWithImpl<$Res>
    implements _$ReviewersCopyWith<$Res> {
  __$ReviewersCopyWithImpl(this._self, this._then);

  final _Reviewers _self;
  final $Res Function(_Reviewers) _then;

/// Create a copy of Reviewers
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reviewerId = null,Object? reviewerType = null,Object? mode = null,}) {
  return _then(_Reviewers(
reviewerId: null == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as int,reviewerType: null == reviewerType ? _self.reviewerType : reviewerType // ignore: cast_nullable_to_non_nullable
as ReviewerType,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as Mode,
  ));
}


}

// dart format on
