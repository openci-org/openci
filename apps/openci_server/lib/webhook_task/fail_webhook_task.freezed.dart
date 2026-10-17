// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fail_webhook_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FailWebhookTaskResult {

 bool get alreadyFailed;
/// Create a copy of FailWebhookTaskResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailWebhookTaskResultCopyWith<FailWebhookTaskResult> get copyWith => _$FailWebhookTaskResultCopyWithImpl<FailWebhookTaskResult>(this as FailWebhookTaskResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FailWebhookTaskResult&&(identical(other.alreadyFailed, alreadyFailed) || other.alreadyFailed == alreadyFailed));
}


@override
int get hashCode => Object.hash(runtimeType,alreadyFailed);

@override
String toString() {
  return 'FailWebhookTaskResult(alreadyFailed: $alreadyFailed)';
}


}

/// @nodoc
abstract mixin class $FailWebhookTaskResultCopyWith<$Res>  {
  factory $FailWebhookTaskResultCopyWith(FailWebhookTaskResult value, $Res Function(FailWebhookTaskResult) _then) = _$FailWebhookTaskResultCopyWithImpl;
@useResult
$Res call({
 bool alreadyFailed
});




}
/// @nodoc
class _$FailWebhookTaskResultCopyWithImpl<$Res>
    implements $FailWebhookTaskResultCopyWith<$Res> {
  _$FailWebhookTaskResultCopyWithImpl(this._self, this._then);

  final FailWebhookTaskResult _self;
  final $Res Function(FailWebhookTaskResult) _then;

/// Create a copy of FailWebhookTaskResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? alreadyFailed = null,}) {
  return _then(_self.copyWith(
alreadyFailed: null == alreadyFailed ? _self.alreadyFailed : alreadyFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FailWebhookTaskResult].
extension FailWebhookTaskResultPatterns on FailWebhookTaskResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FailWebhookTaskResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FailWebhookTaskResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FailWebhookTaskResult value)  $default,){
final _that = this;
switch (_that) {
case _FailWebhookTaskResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FailWebhookTaskResult value)?  $default,){
final _that = this;
switch (_that) {
case _FailWebhookTaskResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool alreadyFailed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FailWebhookTaskResult() when $default != null:
return $default(_that.alreadyFailed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool alreadyFailed)  $default,) {final _that = this;
switch (_that) {
case _FailWebhookTaskResult():
return $default(_that.alreadyFailed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool alreadyFailed)?  $default,) {final _that = this;
switch (_that) {
case _FailWebhookTaskResult() when $default != null:
return $default(_that.alreadyFailed);case _:
  return null;

}
}

}

/// @nodoc


class _FailWebhookTaskResult implements FailWebhookTaskResult {
  const _FailWebhookTaskResult({required this.alreadyFailed});


@override final  bool alreadyFailed;

/// Create a copy of FailWebhookTaskResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FailWebhookTaskResultCopyWith<_FailWebhookTaskResult> get copyWith => __$FailWebhookTaskResultCopyWithImpl<_FailWebhookTaskResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FailWebhookTaskResult&&(identical(other.alreadyFailed, alreadyFailed) || other.alreadyFailed == alreadyFailed));
}


@override
int get hashCode => Object.hash(runtimeType,alreadyFailed);

@override
String toString() {
  return 'FailWebhookTaskResult(alreadyFailed: $alreadyFailed)';
}


}

/// @nodoc
abstract mixin class _$FailWebhookTaskResultCopyWith<$Res> implements $FailWebhookTaskResultCopyWith<$Res> {
  factory _$FailWebhookTaskResultCopyWith(_FailWebhookTaskResult value, $Res Function(_FailWebhookTaskResult) _then) = __$FailWebhookTaskResultCopyWithImpl;
@override @useResult
$Res call({
 bool alreadyFailed
});




}
/// @nodoc
class __$FailWebhookTaskResultCopyWithImpl<$Res>
    implements _$FailWebhookTaskResultCopyWith<$Res> {
  __$FailWebhookTaskResultCopyWithImpl(this._self, this._then);

  final _FailWebhookTaskResult _self;
  final $Res Function(_FailWebhookTaskResult) _then;

/// Create a copy of FailWebhookTaskResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? alreadyFailed = null,}) {
  return _then(_FailWebhookTaskResult(
alreadyFailed: null == alreadyFailed ? _self.alreadyFailed : alreadyFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
