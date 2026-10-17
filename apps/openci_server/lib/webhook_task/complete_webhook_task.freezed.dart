// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'complete_webhook_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CompleteWebhookTaskResult {

 List<String> get jobIds; bool get alreadyCompleted;
/// Create a copy of CompleteWebhookTaskResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompleteWebhookTaskResultCopyWith<CompleteWebhookTaskResult> get copyWith => _$CompleteWebhookTaskResultCopyWithImpl<CompleteWebhookTaskResult>(this as CompleteWebhookTaskResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompleteWebhookTaskResult&&const DeepCollectionEquality().equals(other.jobIds, jobIds)&&(identical(other.alreadyCompleted, alreadyCompleted) || other.alreadyCompleted == alreadyCompleted));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(jobIds),alreadyCompleted);

@override
String toString() {
  return 'CompleteWebhookTaskResult(jobIds: $jobIds, alreadyCompleted: $alreadyCompleted)';
}


}

/// @nodoc
abstract mixin class $CompleteWebhookTaskResultCopyWith<$Res>  {
  factory $CompleteWebhookTaskResultCopyWith(CompleteWebhookTaskResult value, $Res Function(CompleteWebhookTaskResult) _then) = _$CompleteWebhookTaskResultCopyWithImpl;
@useResult
$Res call({
 List<String> jobIds, bool alreadyCompleted
});




}
/// @nodoc
class _$CompleteWebhookTaskResultCopyWithImpl<$Res>
    implements $CompleteWebhookTaskResultCopyWith<$Res> {
  _$CompleteWebhookTaskResultCopyWithImpl(this._self, this._then);

  final CompleteWebhookTaskResult _self;
  final $Res Function(CompleteWebhookTaskResult) _then;

/// Create a copy of CompleteWebhookTaskResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobIds = null,Object? alreadyCompleted = null,}) {
  return _then(_self.copyWith(
jobIds: null == jobIds ? _self.jobIds : jobIds // ignore: cast_nullable_to_non_nullable
as List<String>,alreadyCompleted: null == alreadyCompleted ? _self.alreadyCompleted : alreadyCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CompleteWebhookTaskResult].
extension CompleteWebhookTaskResultPatterns on CompleteWebhookTaskResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompleteWebhookTaskResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompleteWebhookTaskResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompleteWebhookTaskResult value)  $default,){
final _that = this;
switch (_that) {
case _CompleteWebhookTaskResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompleteWebhookTaskResult value)?  $default,){
final _that = this;
switch (_that) {
case _CompleteWebhookTaskResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> jobIds,  bool alreadyCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompleteWebhookTaskResult() when $default != null:
return $default(_that.jobIds,_that.alreadyCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> jobIds,  bool alreadyCompleted)  $default,) {final _that = this;
switch (_that) {
case _CompleteWebhookTaskResult():
return $default(_that.jobIds,_that.alreadyCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> jobIds,  bool alreadyCompleted)?  $default,) {final _that = this;
switch (_that) {
case _CompleteWebhookTaskResult() when $default != null:
return $default(_that.jobIds,_that.alreadyCompleted);case _:
  return null;

}
}

}

/// @nodoc


class _CompleteWebhookTaskResult implements CompleteWebhookTaskResult {
  const _CompleteWebhookTaskResult({required final  List<String> jobIds, required this.alreadyCompleted}): _jobIds = jobIds;


 final  List<String> _jobIds;
@override List<String> get jobIds {
  if (_jobIds is EqualUnmodifiableListView) return _jobIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_jobIds);
}

@override final  bool alreadyCompleted;

/// Create a copy of CompleteWebhookTaskResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompleteWebhookTaskResultCopyWith<_CompleteWebhookTaskResult> get copyWith => __$CompleteWebhookTaskResultCopyWithImpl<_CompleteWebhookTaskResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompleteWebhookTaskResult&&const DeepCollectionEquality().equals(other._jobIds, _jobIds)&&(identical(other.alreadyCompleted, alreadyCompleted) || other.alreadyCompleted == alreadyCompleted));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_jobIds),alreadyCompleted);

@override
String toString() {
  return 'CompleteWebhookTaskResult(jobIds: $jobIds, alreadyCompleted: $alreadyCompleted)';
}


}

/// @nodoc
abstract mixin class _$CompleteWebhookTaskResultCopyWith<$Res> implements $CompleteWebhookTaskResultCopyWith<$Res> {
  factory _$CompleteWebhookTaskResultCopyWith(_CompleteWebhookTaskResult value, $Res Function(_CompleteWebhookTaskResult) _then) = __$CompleteWebhookTaskResultCopyWithImpl;
@override @useResult
$Res call({
 List<String> jobIds, bool alreadyCompleted
});




}
/// @nodoc
class __$CompleteWebhookTaskResultCopyWithImpl<$Res>
    implements _$CompleteWebhookTaskResultCopyWith<$Res> {
  __$CompleteWebhookTaskResultCopyWithImpl(this._self, this._then);

  final _CompleteWebhookTaskResult _self;
  final $Res Function(_CompleteWebhookTaskResult) _then;

/// Create a copy of CompleteWebhookTaskResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobIds = null,Object? alreadyCompleted = null,}) {
  return _then(_CompleteWebhookTaskResult(
jobIds: null == jobIds ? _self._jobIds : jobIds // ignore: cast_nullable_to_non_nullable
as List<String>,alreadyCompleted: null == alreadyCompleted ? _self.alreadyCompleted : alreadyCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
