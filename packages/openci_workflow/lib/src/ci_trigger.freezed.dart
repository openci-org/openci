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



/// @nodoc


class _PushCITrigger extends CITrigger {
  const _PushCITrigger({required this.branch, final  List<String>? paths, final  List<String>? pathsIgnore}): _paths = paths,_pathsIgnore = pathsIgnore,super._();


 final  String branch;
 final  List<String>? _paths;
 List<String>? get paths {
  final value = _paths;
  if (value == null) return null;
  if (_paths is EqualUnmodifiableListView) return _paths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _pathsIgnore;
 List<String>? get pathsIgnore {
  final value = _pathsIgnore;
  if (value == null) return null;
  if (_pathsIgnore is EqualUnmodifiableListView) return _pathsIgnore;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushCITrigger&&(identical(other.branch, branch) || other.branch == branch)&&const DeepCollectionEquality().equals(other._paths, _paths)&&const DeepCollectionEquality().equals(other._pathsIgnore, _pathsIgnore));
}


@override
int get hashCode => Object.hash(runtimeType,branch,const DeepCollectionEquality().hash(_paths),const DeepCollectionEquality().hash(_pathsIgnore));

@override
String toString() {
  return 'CITrigger.push(branch: $branch, paths: $paths, pathsIgnore: $pathsIgnore)';
}


}

/// @nodoc
abstract mixin class _$PushCITriggerCopyWith<$Res> implements $CITriggerCopyWith<$Res> {
  factory _$PushCITriggerCopyWith(_PushCITrigger value, $Res Function(_PushCITrigger) _then) = __$PushCITriggerCopyWithImpl;
@useResult
$Res call({
 String branch, List<String>? paths, List<String>? pathsIgnore
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
@pragma('vm:prefer-inline') $Res call({Object? branch = null,Object? paths = freezed,Object? pathsIgnore = freezed,}) {
  return _then(_PushCITrigger(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,paths: freezed == paths ? _self._paths : paths // ignore: cast_nullable_to_non_nullable
as List<String>?,pathsIgnore: freezed == pathsIgnore ? _self._pathsIgnore : pathsIgnore // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

/// @nodoc


class _PullRequestCITrigger extends CITrigger {
  const _PullRequestCITrigger({required this.branch, final  List<String>? paths, final  List<String>? pathsIgnore}): _paths = paths,_pathsIgnore = pathsIgnore,super._();


 final  String branch;
 final  List<String>? _paths;
 List<String>? get paths {
  final value = _paths;
  if (value == null) return null;
  if (_paths is EqualUnmodifiableListView) return _paths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _pathsIgnore;
 List<String>? get pathsIgnore {
  final value = _pathsIgnore;
  if (value == null) return null;
  if (_pathsIgnore is EqualUnmodifiableListView) return _pathsIgnore;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PullRequestCITrigger&&(identical(other.branch, branch) || other.branch == branch)&&const DeepCollectionEquality().equals(other._paths, _paths)&&const DeepCollectionEquality().equals(other._pathsIgnore, _pathsIgnore));
}


@override
int get hashCode => Object.hash(runtimeType,branch,const DeepCollectionEquality().hash(_paths),const DeepCollectionEquality().hash(_pathsIgnore));

@override
String toString() {
  return 'CITrigger.pullRequest(branch: $branch, paths: $paths, pathsIgnore: $pathsIgnore)';
}


}

/// @nodoc
abstract mixin class _$PullRequestCITriggerCopyWith<$Res> implements $CITriggerCopyWith<$Res> {
  factory _$PullRequestCITriggerCopyWith(_PullRequestCITrigger value, $Res Function(_PullRequestCITrigger) _then) = __$PullRequestCITriggerCopyWithImpl;
@useResult
$Res call({
 String branch, List<String>? paths, List<String>? pathsIgnore
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
@pragma('vm:prefer-inline') $Res call({Object? branch = null,Object? paths = freezed,Object? pathsIgnore = freezed,}) {
  return _then(_PullRequestCITrigger(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,paths: freezed == paths ? _self._paths : paths // ignore: cast_nullable_to_non_nullable
as List<String>?,pathsIgnore: freezed == pathsIgnore ? _self._pathsIgnore : pathsIgnore // ignore: cast_nullable_to_non_nullable
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
