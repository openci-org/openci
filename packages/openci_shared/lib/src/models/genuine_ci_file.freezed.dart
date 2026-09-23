// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'genuine_ci_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GenuineCIFile {

 String get name; String get path; String get content;
/// Create a copy of GenuineCIFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenuineCIFileCopyWith<GenuineCIFile> get copyWith => _$GenuineCIFileCopyWithImpl<GenuineCIFile>(this as GenuineCIFile, _$identity);

  /// Serializes this GenuineCIFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenuineCIFile&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,content);

@override
String toString() {
  return 'GenuineCIFile(name: $name, path: $path, content: $content)';
}


}

/// @nodoc
abstract mixin class $GenuineCIFileCopyWith<$Res>  {
  factory $GenuineCIFileCopyWith(GenuineCIFile value, $Res Function(GenuineCIFile) _then) = _$GenuineCIFileCopyWithImpl;
@useResult
$Res call({
 String name, String path, String content
});




}
/// @nodoc
class _$GenuineCIFileCopyWithImpl<$Res>
    implements $GenuineCIFileCopyWith<$Res> {
  _$GenuineCIFileCopyWithImpl(this._self, this._then);

  final GenuineCIFile _self;
  final $Res Function(GenuineCIFile) _then;

/// Create a copy of GenuineCIFile
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


/// Adds pattern-matching-related methods to [GenuineCIFile].
extension GenuineCIFilePatterns on GenuineCIFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GenuineCIFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GenuineCIFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GenuineCIFile value)  $default,){
final _that = this;
switch (_that) {
case _GenuineCIFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GenuineCIFile value)?  $default,){
final _that = this;
switch (_that) {
case _GenuineCIFile() when $default != null:
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
case _GenuineCIFile() when $default != null:
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
case _GenuineCIFile():
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
case _GenuineCIFile() when $default != null:
return $default(_that.name,_that.path,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GenuineCIFile implements GenuineCIFile {
  const _GenuineCIFile({required this.name, required this.path, required this.content});
  factory _GenuineCIFile.fromJson(Map<String, dynamic> json) => _$GenuineCIFileFromJson(json);

@override final  String name;
@override final  String path;
@override final  String content;

/// Create a copy of GenuineCIFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenuineCIFileCopyWith<_GenuineCIFile> get copyWith => __$GenuineCIFileCopyWithImpl<_GenuineCIFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenuineCIFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GenuineCIFile&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,content);

@override
String toString() {
  return 'GenuineCIFile(name: $name, path: $path, content: $content)';
}


}

/// @nodoc
abstract mixin class _$GenuineCIFileCopyWith<$Res> implements $GenuineCIFileCopyWith<$Res> {
  factory _$GenuineCIFileCopyWith(_GenuineCIFile value, $Res Function(_GenuineCIFile) _then) = __$GenuineCIFileCopyWithImpl;
@override @useResult
$Res call({
 String name, String path, String content
});




}
/// @nodoc
class __$GenuineCIFileCopyWithImpl<$Res>
    implements _$GenuineCIFileCopyWith<$Res> {
  __$GenuineCIFileCopyWithImpl(this._self, this._then);

  final _GenuineCIFile _self;
  final $Res Function(_GenuineCIFile) _then;

/// Create a copy of GenuineCIFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? path = null,Object? content = null,}) {
  return _then(_GenuineCIFile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
