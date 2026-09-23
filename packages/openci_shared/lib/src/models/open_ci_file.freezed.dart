// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'open_ci_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OpenCIFile {

 String get name; String get path; String get content;
/// Create a copy of OpenCIFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpenCIFileCopyWith<OpenCIFile> get copyWith => _$OpenCIFileCopyWithImpl<OpenCIFile>(this as OpenCIFile, _$identity);

  /// Serializes this OpenCIFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpenCIFile&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,content);

@override
String toString() {
  return 'OpenCIFile(name: $name, path: $path, content: $content)';
}


}

/// @nodoc
abstract mixin class $OpenCIFileCopyWith<$Res>  {
  factory $OpenCIFileCopyWith(OpenCIFile value, $Res Function(OpenCIFile) _then) = _$OpenCIFileCopyWithImpl;
@useResult
$Res call({
 String name, String path, String content
});




}
/// @nodoc
class _$OpenCIFileCopyWithImpl<$Res>
    implements $OpenCIFileCopyWith<$Res> {
  _$OpenCIFileCopyWithImpl(this._self, this._then);

  final OpenCIFile _self;
  final $Res Function(OpenCIFile) _then;

/// Create a copy of OpenCIFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? path = null,Object? content = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OpenCIFile].
extension OpenCIFilePatterns on OpenCIFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpenCIFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpenCIFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpenCIFile value)  $default,){
final _that = this;
switch (_that) {
case _OpenCIFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpenCIFile value)?  $default,){
final _that = this;
switch (_that) {
case _OpenCIFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String path,  String content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpenCIFile() when $default != null:
return $default(_that.name,_that.path,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String path,  String content)  $default,) {final _that = this;
switch (_that) {
case _OpenCIFile():
return $default(_that.name,_that.path,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String path,  String content)?  $default,) {final _that = this;
switch (_that) {
case _OpenCIFile() when $default != null:
return $default(_that.name,_that.path,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpenCIFile implements OpenCIFile {
  const _OpenCIFile({required this.name, required this.path, required this.content});
  factory _OpenCIFile.fromJson(Map<String, dynamic> json) => _$OpenCIFileFromJson(json);

@override final  String name;
@override final  String path;
@override final  String content;

/// Create a copy of OpenCIFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenCIFileCopyWith<_OpenCIFile> get copyWith => __$OpenCIFileCopyWithImpl<_OpenCIFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpenCIFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenCIFile&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,content);

@override
String toString() {
  return 'OpenCIFile(name: $name, path: $path, content: $content)';
}


}

/// @nodoc
abstract mixin class _$OpenCIFileCopyWith<$Res> implements $OpenCIFileCopyWith<$Res> {
  factory _$OpenCIFileCopyWith(_OpenCIFile value, $Res Function(_OpenCIFile) _then) = __$OpenCIFileCopyWithImpl;
@override @useResult
$Res call({
 String name, String path, String content
});




}
/// @nodoc
class __$OpenCIFileCopyWithImpl<$Res>
    implements _$OpenCIFileCopyWith<$Res> {
  __$OpenCIFileCopyWithImpl(this._self, this._then);

  final _OpenCIFile _self;
  final $Res Function(_OpenCIFile) _then;

/// Create a copy of OpenCIFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? path = null,Object? content = null,}) {
  return _then(_OpenCIFile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
