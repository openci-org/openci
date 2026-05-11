// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow_file_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkflowFile {

 String get name; String get path; String get content; String get repository; String get branch;
/// Create a copy of WorkflowFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowFileCopyWith<WorkflowFile> get copyWith => _$WorkflowFileCopyWithImpl<WorkflowFile>(this as WorkflowFile, _$identity);

  /// Serializes this WorkflowFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowFile&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.content, content) || other.content == content)&&(identical(other.repository, repository) || other.repository == repository)&&(identical(other.branch, branch) || other.branch == branch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,content,repository,branch);

@override
String toString() {
  return 'WorkflowFile(name: $name, path: $path, content: $content, repository: $repository, branch: $branch)';
}


}

/// @nodoc
abstract mixin class $WorkflowFileCopyWith<$Res>  {
  factory $WorkflowFileCopyWith(WorkflowFile value, $Res Function(WorkflowFile) _then) = _$WorkflowFileCopyWithImpl;
@useResult
$Res call({
 String name, String path, String content, String repository, String branch
});




}
/// @nodoc
class _$WorkflowFileCopyWithImpl<$Res>
    implements $WorkflowFileCopyWith<$Res> {
  _$WorkflowFileCopyWithImpl(this._self, this._then);

  final WorkflowFile _self;
  final $Res Function(WorkflowFile) _then;

/// Create a copy of WorkflowFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? path = null,Object? content = null,Object? repository = null,Object? branch = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,repository: null == repository ? _self.repository : repository // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowFile].
extension WorkflowFilePatterns on WorkflowFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowFile value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowFile value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String path,  String content,  String repository,  String branch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowFile() when $default != null:
return $default(_that.name,_that.path,_that.content,_that.repository,_that.branch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String path,  String content,  String repository,  String branch)  $default,) {final _that = this;
switch (_that) {
case _WorkflowFile():
return $default(_that.name,_that.path,_that.content,_that.repository,_that.branch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String path,  String content,  String repository,  String branch)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowFile() when $default != null:
return $default(_that.name,_that.path,_that.content,_that.repository,_that.branch);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkflowFile implements WorkflowFile {
  const _WorkflowFile({required this.name, required this.path, required this.content, required this.repository, required this.branch});
  factory _WorkflowFile.fromJson(Map<String, dynamic> json) => _$WorkflowFileFromJson(json);

@override final  String name;
@override final  String path;
@override final  String content;
@override final  String repository;
@override final  String branch;

/// Create a copy of WorkflowFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowFileCopyWith<_WorkflowFile> get copyWith => __$WorkflowFileCopyWithImpl<_WorkflowFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowFile&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.content, content) || other.content == content)&&(identical(other.repository, repository) || other.repository == repository)&&(identical(other.branch, branch) || other.branch == branch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,content,repository,branch);

@override
String toString() {
  return 'WorkflowFile(name: $name, path: $path, content: $content, repository: $repository, branch: $branch)';
}


}

/// @nodoc
abstract mixin class _$WorkflowFileCopyWith<$Res> implements $WorkflowFileCopyWith<$Res> {
  factory _$WorkflowFileCopyWith(_WorkflowFile value, $Res Function(_WorkflowFile) _then) = __$WorkflowFileCopyWithImpl;
@override @useResult
$Res call({
 String name, String path, String content, String repository, String branch
});




}
/// @nodoc
class __$WorkflowFileCopyWithImpl<$Res>
    implements _$WorkflowFileCopyWith<$Res> {
  __$WorkflowFileCopyWithImpl(this._self, this._then);

  final _WorkflowFile _self;
  final $Res Function(_WorkflowFile) _then;

/// Create a copy of WorkflowFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? path = null,Object? content = null,Object? repository = null,Object? branch = null,}) {
  return _then(_WorkflowFile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,repository: null == repository ? _self.repository : repository // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
