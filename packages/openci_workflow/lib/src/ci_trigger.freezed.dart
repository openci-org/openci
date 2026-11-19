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





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CITrigger);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CITrigger()';
}


}

/// @nodoc
class $CITriggerCopyWith<$Res>  {
$CITriggerCopyWith(CITrigger _, $Res Function(CITrigger) __);
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _PushCITrigger value)?  push,TResult Function( _PullRequestCITrigger value)?  pullRequest,TResult Function( _ReleaseCITrigger value)?  release,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushCITrigger() when push != null:
return push(_that);case _PullRequestCITrigger() when pullRequest != null:
return pullRequest(_that);case _ReleaseCITrigger() when release != null:
return release(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _PushCITrigger value)  push,required TResult Function( _PullRequestCITrigger value)  pullRequest,required TResult Function( _ReleaseCITrigger value)  release,}){
final _that = this;
switch (_that) {
case _PushCITrigger():
return push(_that);case _PullRequestCITrigger():
return pullRequest(_that);case _ReleaseCITrigger():
return release(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _PushCITrigger value)?  push,TResult? Function( _PullRequestCITrigger value)?  pullRequest,TResult? Function( _ReleaseCITrigger value)?  release,}){
final _that = this;
switch (_that) {
case _PushCITrigger() when push != null:
return push(_that);case _PullRequestCITrigger() when pullRequest != null:
return pullRequest(_that);case _ReleaseCITrigger() when release != null:
return release(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String branch,  List<String>? paths)?  push,TResult Function( String branch,  List<String>? paths)?  pullRequest,TResult Function( String tag)?  release,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushCITrigger() when push != null:
return push(_that.branch,_that.paths);case _PullRequestCITrigger() when pullRequest != null:
return pullRequest(_that.branch,_that.paths);case _ReleaseCITrigger() when release != null:
return release(_that.tag);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String branch,  List<String>? paths)  push,required TResult Function( String branch,  List<String>? paths)  pullRequest,required TResult Function( String tag)  release,}) {final _that = this;
switch (_that) {
case _PushCITrigger():
return push(_that.branch,_that.paths);case _PullRequestCITrigger():
return pullRequest(_that.branch,_that.paths);case _ReleaseCITrigger():
return release(_that.tag);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String branch,  List<String>? paths)?  push,TResult? Function( String branch,  List<String>? paths)?  pullRequest,TResult? Function( String tag)?  release,}) {final _that = this;
switch (_that) {
case _PushCITrigger() when push != null:
return push(_that.branch,_that.paths);case _PullRequestCITrigger() when pullRequest != null:
return pullRequest(_that.branch,_that.paths);case _ReleaseCITrigger() when release != null:
return release(_that.tag);case _:
  return null;

}
}

}

/// @nodoc


class _PushCITrigger extends CITrigger {
  const _PushCITrigger({required this.branch, final  List<String>? paths}): _paths = paths,super._();


 final  String branch;
 final  List<String>? _paths;
 List<String>? get paths {
  final value = _paths;
  if (value == null) return null;
  if (_paths is EqualUnmodifiableListView) return _paths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of CITrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushCITriggerCopyWith<_PushCITrigger> get copyWith => __$PushCITriggerCopyWithImpl<_PushCITrigger>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushCITrigger&&(identical(other.branch, branch) || other.branch == branch)&&const DeepCollectionEquality().equals(other._paths, _paths));
}


@override
int get hashCode => Object.hash(runtimeType,branch,const DeepCollectionEquality().hash(_paths));

@override
String toString() {
  return 'CITrigger.push(branch: $branch, paths: $paths)';
}


}

/// @nodoc
abstract mixin class _$PushCITriggerCopyWith<$Res> implements $CITriggerCopyWith<$Res> {
  factory _$PushCITriggerCopyWith(_PushCITrigger value, $Res Function(_PushCITrigger) _then) = __$PushCITriggerCopyWithImpl;
@useResult
$Res call({
 String branch, List<String>? paths
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
@pragma('vm:prefer-inline') $Res call({Object? branch = null,Object? paths = freezed,}) {
  return _then(_PushCITrigger(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,paths: freezed == paths ? _self._paths : paths // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

/// @nodoc


class _PullRequestCITrigger extends CITrigger {
  const _PullRequestCITrigger({required this.branch, final  List<String>? paths}): _paths = paths,super._();


 final  String branch;
 final  List<String>? _paths;
 List<String>? get paths {
  final value = _paths;
  if (value == null) return null;
  if (_paths is EqualUnmodifiableListView) return _paths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of CITrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PullRequestCITriggerCopyWith<_PullRequestCITrigger> get copyWith => __$PullRequestCITriggerCopyWithImpl<_PullRequestCITrigger>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PullRequestCITrigger&&(identical(other.branch, branch) || other.branch == branch)&&const DeepCollectionEquality().equals(other._paths, _paths));
}


@override
int get hashCode => Object.hash(runtimeType,branch,const DeepCollectionEquality().hash(_paths));

@override
String toString() {
  return 'CITrigger.pullRequest(branch: $branch, paths: $paths)';
}


}

/// @nodoc
abstract mixin class _$PullRequestCITriggerCopyWith<$Res> implements $CITriggerCopyWith<$Res> {
  factory _$PullRequestCITriggerCopyWith(_PullRequestCITrigger value, $Res Function(_PullRequestCITrigger) _then) = __$PullRequestCITriggerCopyWithImpl;
@useResult
$Res call({
 String branch, List<String>? paths
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
@pragma('vm:prefer-inline') $Res call({Object? branch = null,Object? paths = freezed,}) {
  return _then(_PullRequestCITrigger(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,paths: freezed == paths ? _self._paths : paths // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

/// @nodoc


class _ReleaseCITrigger extends CITrigger {
  const _ReleaseCITrigger({this.tag = '*'}): super._();


@JsonKey() final  String tag;

/// Create a copy of CITrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReleaseCITriggerCopyWith<_ReleaseCITrigger> get copyWith => __$ReleaseCITriggerCopyWithImpl<_ReleaseCITrigger>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReleaseCITrigger&&(identical(other.tag, tag) || other.tag == tag));
}


@override
int get hashCode => Object.hash(runtimeType,tag);

@override
String toString() {
  return 'CITrigger.release(tag: $tag)';
}


}

/// @nodoc
abstract mixin class _$ReleaseCITriggerCopyWith<$Res> implements $CITriggerCopyWith<$Res> {
  factory _$ReleaseCITriggerCopyWith(_ReleaseCITrigger value, $Res Function(_ReleaseCITrigger) _then) = __$ReleaseCITriggerCopyWithImpl;
@useResult
$Res call({
 String tag
});




}
/// @nodoc
class __$ReleaseCITriggerCopyWithImpl<$Res>
    implements _$ReleaseCITriggerCopyWith<$Res> {
  __$ReleaseCITriggerCopyWithImpl(this._self, this._then);

  final _ReleaseCITrigger _self;
  final $Res Function(_ReleaseCITrigger) _then;

/// Create a copy of CITrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tag = null,}) {
  return _then(_ReleaseCITrigger(
tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
