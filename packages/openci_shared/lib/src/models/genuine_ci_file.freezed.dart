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
mixin _$GenuineCiFile {

 String get name; String get path; String get content;
/// Create a copy of GenuineCiFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenuineCiFileCopyWith<GenuineCiFile> get copyWith => _$GenuineCiFileCopyWithImpl<GenuineCiFile>(this as GenuineCiFile, _$identity);

  /// Serializes this GenuineCiFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenuineCiFile&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,content);

@override
String toString() {
  return 'GenuineCiFile(name: $name, path: $path, content: $content)';
}


}

/// @nodoc
abstract mixin class $GenuineCiFileCopyWith<$Res>  {
  factory $GenuineCiFileCopyWith(GenuineCiFile value, $Res Function(GenuineCiFile) _then) = _$GenuineCiFileCopyWithImpl;
@useResult
$Res call({
 String name, String path, String content
});




}
/// @nodoc
class _$GenuineCiFileCopyWithImpl<$Res>
    implements $GenuineCiFileCopyWith<$Res> {
  _$GenuineCiFileCopyWithImpl(this._self, this._then);

  final GenuineCiFile _self;
  final $Res Function(GenuineCiFile) _then;

/// Create a copy of GenuineCiFile
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


/// Adds pattern-matching-related methods to [GenuineCiFile].
extension GenuineCiFilePatterns on GenuineCiFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GenuineCiFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GenuineCiFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GenuineCiFile value)  $default,){
final _that = this;
switch (_that) {
case _GenuineCiFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GenuineCiFile value)?  $default,){
final _that = this;
switch (_that) {
case _GenuineCiFile() when $default != null:
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
case _GenuineCiFile() when $default != null:
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
case _GenuineCiFile():
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
case _GenuineCiFile() when $default != null:
return $default(_that.name,_that.path,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GenuineCiFile implements GenuineCiFile {
  const _GenuineCiFile({required this.name, required this.path, required this.content});
  factory _GenuineCiFile.fromJson(Map<String, dynamic> json) => _$GenuineCiFileFromJson(json);

@override final  String name;
@override final  String path;
@override final  String content;

/// Create a copy of GenuineCiFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenuineCiFileCopyWith<_GenuineCiFile> get copyWith => __$GenuineCiFileCopyWithImpl<_GenuineCiFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenuineCiFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GenuineCiFile&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,content);

@override
String toString() {
  return 'GenuineCiFile(name: $name, path: $path, content: $content)';
}


}

/// @nodoc
abstract mixin class _$GenuineCiFileCopyWith<$Res> implements $GenuineCiFileCopyWith<$Res> {
  factory _$GenuineCiFileCopyWith(_GenuineCiFile value, $Res Function(_GenuineCiFile) _then) = __$GenuineCiFileCopyWithImpl;
@override @useResult
$Res call({
 String name, String path, String content
});




}
/// @nodoc
class __$GenuineCiFileCopyWithImpl<$Res>
    implements _$GenuineCiFileCopyWith<$Res> {
  __$GenuineCiFileCopyWithImpl(this._self, this._then);

  final _GenuineCiFile _self;
  final $Res Function(_GenuineCiFile) _then;

/// Create a copy of GenuineCiFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? path = null,Object? content = null,}) {
  return _then(_GenuineCiFile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
