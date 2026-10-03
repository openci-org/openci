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
mixin _$CITrigger {

 String get branch;
/// Create a copy of CITrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CITriggerCopyWith<CITrigger> get copyWith => _$CITriggerCopyWithImpl<CITrigger>(this as CITrigger, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CITrigger&&(identical(other.branch, branch) || other.branch == branch));
}


@override
int get hashCode => Object.hash(runtimeType,branch);

@override
String toString() {
  return 'CITrigger(branch: $branch)';
}


}

/// @nodoc
abstract mixin class $CITriggerCopyWith<$Res>  {
  factory $CITriggerCopyWith(CITrigger value, $Res Function(CITrigger) _then) = _$CITriggerCopyWithImpl;
@useResult
$Res call({
 String branch
});




}
/// @nodoc
class _$CITriggerCopyWithImpl<$Res>
    implements $CITriggerCopyWith<$Res> {
  _$CITriggerCopyWithImpl(this._self, this._then);

  final CITrigger _self;
  final $Res Function(CITrigger) _then;

/// Create a copy of CITrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? branch = null,}) {
  return _then(_self.copyWith(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CITrigger].
extension CITriggerPatterns on CITrigger {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _PushCITrigger value)?  push,TResult Function( _PullRequestCITrigger value)?  pullRequest,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushCITrigger() when push != null:
return push(_that);case _PullRequestCITrigger() when pullRequest != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _PushCITrigger value)  push,required TResult Function( _PullRequestCITrigger value)  pullRequest,}){
final _that = this;
switch (_that) {
case _PushCITrigger():
return push(_that);case _PullRequestCITrigger():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _PushCITrigger value)?  push,TResult? Function( _PullRequestCITrigger value)?  pullRequest,}){
final _that = this;
switch (_that) {
case _PushCITrigger() when push != null:
return push(_that);case _PullRequestCITrigger() when pullRequest != null:
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
case _PushCITrigger() when push != null:
return push(_that.branch);case _PullRequestCITrigger() when pullRequest != null:
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
case _PushCITrigger():
return push(_that.branch);case _PullRequestCITrigger():
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
case _PushCITrigger() when push != null:
return push(_that.branch);case _PullRequestCITrigger() when pullRequest != null:
return pullRequest(_that.branch);case _:
  return null;

}
}

}

/// @nodoc


class _PushCITrigger implements CITrigger {
  const _PushCITrigger({required this.branch});
  

@override final  String branch;

/// Create a copy of CITrigger
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushCITriggerCopyWith<_PushCITrigger> get copyWith => __$PushCITriggerCopyWithImpl<_PushCITrigger>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushCITrigger&&(identical(other.branch, branch) || other.branch == branch));
}


@override
int get hashCode => Object.hash(runtimeType,branch);

@override
String toString() {
  return 'CITrigger.push(branch: $branch)';
}


}

/// @nodoc
abstract mixin class _$PushCITriggerCopyWith<$Res> implements $CITriggerCopyWith<$Res> {
  factory _$PushCITriggerCopyWith(_PushCITrigger value, $Res Function(_PushCITrigger) _then) = __$PushCITriggerCopyWithImpl;
@override @useResult
$Res call({
 String branch
});




}
/// @nodoc
class __$PushCITriggerCopyWithImpl<$Res>
    implements _$PushCITriggerCopyWith<$Res> {
  __$PushCITriggerCopyWithImpl(this._self, this._then);

  final _PushCITrigger _self;
  final $Res Function(_PushCITrigger) _then;

/// Create a copy of CITrigger
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branch = null,}) {
  return _then(_PushCITrigger(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _PullRequestCITrigger implements CITrigger {
  const _PullRequestCITrigger({required this.branch});
  

@override final  String branch;

/// Create a copy of CITrigger
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PullRequestCITriggerCopyWith<_PullRequestCITrigger> get copyWith => __$PullRequestCITriggerCopyWithImpl<_PullRequestCITrigger>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PullRequestCITrigger&&(identical(other.branch, branch) || other.branch == branch));
}


@override
int get hashCode => Object.hash(runtimeType,branch);

@override
String toString() {
  return 'CITrigger.pullRequest(branch: $branch)';
}


}

/// @nodoc
abstract mixin class _$PullRequestCITriggerCopyWith<$Res> implements $CITriggerCopyWith<$Res> {
  factory _$PullRequestCITriggerCopyWith(_PullRequestCITrigger value, $Res Function(_PullRequestCITrigger) _then) = __$PullRequestCITriggerCopyWithImpl;
@override @useResult
$Res call({
 String branch
});




}
/// @nodoc
class __$PullRequestCITriggerCopyWithImpl<$Res>
    implements _$PullRequestCITriggerCopyWith<$Res> {
  __$PullRequestCITriggerCopyWithImpl(this._self, this._then);

  final _PullRequestCITrigger _self;
  final $Res Function(_PullRequestCITrigger) _then;

/// Create a copy of CITrigger
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branch = null,}) {
  return _then(_PullRequestCITrigger(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
