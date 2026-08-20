// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ci_trigger.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CiTrigger {

 String get branch;
/// Create a copy of CiTrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CiTriggerCopyWith<CiTrigger> get copyWith => _$CiTriggerCopyWithImpl<CiTrigger>(this as CiTrigger, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CiTrigger&&(identical(other.branch, branch) || other.branch == branch));
}


@override
int get hashCode => Object.hash(runtimeType,branch);

@override
String toString() {
  return 'CiTrigger(branch: $branch)';
}


}

/// @nodoc
abstract mixin class $CiTriggerCopyWith<$Res>  {
  factory $CiTriggerCopyWith(CiTrigger value, $Res Function(CiTrigger) _then) = _$CiTriggerCopyWithImpl;
@useResult
$Res call({
 String branch
});




}
/// @nodoc
class _$CiTriggerCopyWithImpl<$Res>
    implements $CiTriggerCopyWith<$Res> {
  _$CiTriggerCopyWithImpl(this._self, this._then);

  final CiTrigger _self;
  final $Res Function(CiTrigger) _then;

/// Create a copy of CiTrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? branch = null,}) {
  return _then(_self.copyWith(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CiTrigger].
extension CiTriggerPatterns on CiTrigger {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _PushCiTrigger value)?  push,TResult Function( _PullRequestCiTrigger value)?  pullRequest,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushCiTrigger() when push != null:
return push(_that);case _PullRequestCiTrigger() when pullRequest != null:
return pullRequest(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _PushCiTrigger value)  push,required TResult Function( _PullRequestCiTrigger value)  pullRequest,}){
final _that = this;
switch (_that) {
case _PushCiTrigger():
return push(_that);case _PullRequestCiTrigger():
return pullRequest(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _PushCiTrigger value)?  push,TResult? Function( _PullRequestCiTrigger value)?  pullRequest,}){
final _that = this;
switch (_that) {
case _PushCiTrigger() when push != null:
return push(_that);case _PullRequestCiTrigger() when pullRequest != null:
return pullRequest(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String branch)?  push,TResult Function( String branch)?  pullRequest,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushCiTrigger() when push != null:
return push(_that.branch);case _PullRequestCiTrigger() when pullRequest != null:
return pullRequest(_that.branch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String branch)  push,required TResult Function( String branch)  pullRequest,}) {final _that = this;
switch (_that) {
case _PushCiTrigger():
return push(_that.branch);case _PullRequestCiTrigger():
return pullRequest(_that.branch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String branch)?  push,TResult? Function( String branch)?  pullRequest,}) {final _that = this;
switch (_that) {
case _PushCiTrigger() when push != null:
return push(_that.branch);case _PullRequestCiTrigger() when pullRequest != null:
return pullRequest(_that.branch);case _:
  return null;

}
}

}

/// @nodoc


class _PushCiTrigger implements CiTrigger {
  const _PushCiTrigger({required this.branch});
  

@override final  String branch;

/// Create a copy of CiTrigger
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushCiTriggerCopyWith<_PushCiTrigger> get copyWith => __$PushCiTriggerCopyWithImpl<_PushCiTrigger>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushCiTrigger&&(identical(other.branch, branch) || other.branch == branch));
}


@override
int get hashCode => Object.hash(runtimeType,branch);

@override
String toString() {
  return 'CiTrigger.push(branch: $branch)';
}


}

/// @nodoc
abstract mixin class _$PushCiTriggerCopyWith<$Res> implements $CiTriggerCopyWith<$Res> {
  factory _$PushCiTriggerCopyWith(_PushCiTrigger value, $Res Function(_PushCiTrigger) _then) = __$PushCiTriggerCopyWithImpl;
@override @useResult
$Res call({
 String branch
});




}
/// @nodoc
class __$PushCiTriggerCopyWithImpl<$Res>
    implements _$PushCiTriggerCopyWith<$Res> {
  __$PushCiTriggerCopyWithImpl(this._self, this._then);

  final _PushCiTrigger _self;
  final $Res Function(_PushCiTrigger) _then;

/// Create a copy of CiTrigger
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branch = null,}) {
  return _then(_PushCiTrigger(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _PullRequestCiTrigger implements CiTrigger {
  const _PullRequestCiTrigger({required this.branch});
  

@override final  String branch;

/// Create a copy of CiTrigger
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PullRequestCiTriggerCopyWith<_PullRequestCiTrigger> get copyWith => __$PullRequestCiTriggerCopyWithImpl<_PullRequestCiTrigger>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PullRequestCiTrigger&&(identical(other.branch, branch) || other.branch == branch));
}


@override
int get hashCode => Object.hash(runtimeType,branch);

@override
String toString() {
  return 'CiTrigger.pullRequest(branch: $branch)';
}


}

/// @nodoc
abstract mixin class _$PullRequestCiTriggerCopyWith<$Res> implements $CiTriggerCopyWith<$Res> {
  factory _$PullRequestCiTriggerCopyWith(_PullRequestCiTrigger value, $Res Function(_PullRequestCiTrigger) _then) = __$PullRequestCiTriggerCopyWithImpl;
@override @useResult
$Res call({
 String branch
});




}
/// @nodoc
class __$PullRequestCiTriggerCopyWithImpl<$Res>
    implements _$PullRequestCiTriggerCopyWith<$Res> {
  __$PullRequestCiTriggerCopyWithImpl(this._self, this._then);

  final _PullRequestCiTrigger _self;
  final $Res Function(_PullRequestCiTrigger) _then;

/// Create a copy of CiTrigger
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branch = null,}) {
  return _then(_PullRequestCiTrigger(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
