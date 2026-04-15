// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'annotations2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Annotations2 {

/// The path of the file to add an annotation to. For example, `assets/css/main.css`.
 String get path;/// The start line of the annotation. Line numbers start at 1.
@JsonKey(name: 'start_line') int get startLine;/// The end line of the annotation.
@JsonKey(name: 'end_line') int get endLine;/// The level of the annotation.
@JsonKey(name: 'annotation_level') AnnotationLevel get annotationLevel;/// A short description of the feedback for these lines of code. The maximum size is 64 KB.
 String get message;/// The start column of the annotation. Annotations only support `start_column` and `end_column` on the same line. Omit this parameter if `start_line` and `end_line` have different values. Column numbers start at 1.
@JsonKey(name: 'start_column') int? get startColumn;/// The end column of the annotation. Annotations only support `start_column` and `end_column` on the same line. Omit this parameter if `start_line` and `end_line` have different values.
@JsonKey(name: 'end_column') int? get endColumn;/// The title that represents the annotation. The maximum size is 255 characters.
 String? get title;/// Details about this annotation. The maximum size is 64 KB.
@JsonKey(name: 'raw_details') String? get rawDetails;
/// Create a copy of Annotations2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Annotations2CopyWith<Annotations2> get copyWith => _$Annotations2CopyWithImpl<Annotations2>(this as Annotations2, _$identity);

  /// Serializes this Annotations2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Annotations2&&(identical(other.path, path) || other.path == path)&&(identical(other.startLine, startLine) || other.startLine == startLine)&&(identical(other.endLine, endLine) || other.endLine == endLine)&&(identical(other.annotationLevel, annotationLevel) || other.annotationLevel == annotationLevel)&&(identical(other.message, message) || other.message == message)&&(identical(other.startColumn, startColumn) || other.startColumn == startColumn)&&(identical(other.endColumn, endColumn) || other.endColumn == endColumn)&&(identical(other.title, title) || other.title == title)&&(identical(other.rawDetails, rawDetails) || other.rawDetails == rawDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,startLine,endLine,annotationLevel,message,startColumn,endColumn,title,rawDetails);

@override
String toString() {
  return 'Annotations2(path: $path, startLine: $startLine, endLine: $endLine, annotationLevel: $annotationLevel, message: $message, startColumn: $startColumn, endColumn: $endColumn, title: $title, rawDetails: $rawDetails)';
}


}

/// @nodoc
abstract mixin class $Annotations2CopyWith<$Res>  {
  factory $Annotations2CopyWith(Annotations2 value, $Res Function(Annotations2) _then) = _$Annotations2CopyWithImpl;
@useResult
$Res call({
 String path,@JsonKey(name: 'start_line') int startLine,@JsonKey(name: 'end_line') int endLine,@JsonKey(name: 'annotation_level') AnnotationLevel annotationLevel, String message,@JsonKey(name: 'start_column') int? startColumn,@JsonKey(name: 'end_column') int? endColumn, String? title,@JsonKey(name: 'raw_details') String? rawDetails
});




}
/// @nodoc
class _$Annotations2CopyWithImpl<$Res>
    implements $Annotations2CopyWith<$Res> {
  _$Annotations2CopyWithImpl(this._self, this._then);

  final Annotations2 _self;
  final $Res Function(Annotations2) _then;

/// Create a copy of Annotations2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? startLine = null,Object? endLine = null,Object? annotationLevel = null,Object? message = null,Object? startColumn = freezed,Object? endColumn = freezed,Object? title = freezed,Object? rawDetails = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,startLine: null == startLine ? _self.startLine : startLine // ignore: cast_nullable_to_non_nullable
as int,endLine: null == endLine ? _self.endLine : endLine // ignore: cast_nullable_to_non_nullable
as int,annotationLevel: null == annotationLevel ? _self.annotationLevel : annotationLevel // ignore: cast_nullable_to_non_nullable
as AnnotationLevel,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,startColumn: freezed == startColumn ? _self.startColumn : startColumn // ignore: cast_nullable_to_non_nullable
as int?,endColumn: freezed == endColumn ? _self.endColumn : endColumn // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,rawDetails: freezed == rawDetails ? _self.rawDetails : rawDetails // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Annotations2].
extension Annotations2Patterns on Annotations2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Annotations2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Annotations2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Annotations2 value)  $default,){
final _that = this;
switch (_that) {
case _Annotations2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Annotations2 value)?  $default,){
final _that = this;
switch (_that) {
case _Annotations2() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path, @JsonKey(name: 'start_line')  int startLine, @JsonKey(name: 'end_line')  int endLine, @JsonKey(name: 'annotation_level')  AnnotationLevel annotationLevel,  String message, @JsonKey(name: 'start_column')  int? startColumn, @JsonKey(name: 'end_column')  int? endColumn,  String? title, @JsonKey(name: 'raw_details')  String? rawDetails)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Annotations2() when $default != null:
return $default(_that.path,_that.startLine,_that.endLine,_that.annotationLevel,_that.message,_that.startColumn,_that.endColumn,_that.title,_that.rawDetails);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path, @JsonKey(name: 'start_line')  int startLine, @JsonKey(name: 'end_line')  int endLine, @JsonKey(name: 'annotation_level')  AnnotationLevel annotationLevel,  String message, @JsonKey(name: 'start_column')  int? startColumn, @JsonKey(name: 'end_column')  int? endColumn,  String? title, @JsonKey(name: 'raw_details')  String? rawDetails)  $default,) {final _that = this;
switch (_that) {
case _Annotations2():
return $default(_that.path,_that.startLine,_that.endLine,_that.annotationLevel,_that.message,_that.startColumn,_that.endColumn,_that.title,_that.rawDetails);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path, @JsonKey(name: 'start_line')  int startLine, @JsonKey(name: 'end_line')  int endLine, @JsonKey(name: 'annotation_level')  AnnotationLevel annotationLevel,  String message, @JsonKey(name: 'start_column')  int? startColumn, @JsonKey(name: 'end_column')  int? endColumn,  String? title, @JsonKey(name: 'raw_details')  String? rawDetails)?  $default,) {final _that = this;
switch (_that) {
case _Annotations2() when $default != null:
return $default(_that.path,_that.startLine,_that.endLine,_that.annotationLevel,_that.message,_that.startColumn,_that.endColumn,_that.title,_that.rawDetails);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Annotations2 implements Annotations2 {
  const _Annotations2({required this.path, @JsonKey(name: 'start_line') required this.startLine, @JsonKey(name: 'end_line') required this.endLine, @JsonKey(name: 'annotation_level') required this.annotationLevel, required this.message, @JsonKey(name: 'start_column') this.startColumn, @JsonKey(name: 'end_column') this.endColumn, this.title, @JsonKey(name: 'raw_details') this.rawDetails});
  factory _Annotations2.fromJson(Map<String, dynamic> json) => _$Annotations2FromJson(json);

/// The path of the file to add an annotation to. For example, `assets/css/main.css`.
@override final  String path;
/// The start line of the annotation. Line numbers start at 1.
@override@JsonKey(name: 'start_line') final  int startLine;
/// The end line of the annotation.
@override@JsonKey(name: 'end_line') final  int endLine;
/// The level of the annotation.
@override@JsonKey(name: 'annotation_level') final  AnnotationLevel annotationLevel;
/// A short description of the feedback for these lines of code. The maximum size is 64 KB.
@override final  String message;
/// The start column of the annotation. Annotations only support `start_column` and `end_column` on the same line. Omit this parameter if `start_line` and `end_line` have different values. Column numbers start at 1.
@override@JsonKey(name: 'start_column') final  int? startColumn;
/// The end column of the annotation. Annotations only support `start_column` and `end_column` on the same line. Omit this parameter if `start_line` and `end_line` have different values.
@override@JsonKey(name: 'end_column') final  int? endColumn;
/// The title that represents the annotation. The maximum size is 255 characters.
@override final  String? title;
/// Details about this annotation. The maximum size is 64 KB.
@override@JsonKey(name: 'raw_details') final  String? rawDetails;

/// Create a copy of Annotations2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Annotations2CopyWith<_Annotations2> get copyWith => __$Annotations2CopyWithImpl<_Annotations2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Annotations2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Annotations2&&(identical(other.path, path) || other.path == path)&&(identical(other.startLine, startLine) || other.startLine == startLine)&&(identical(other.endLine, endLine) || other.endLine == endLine)&&(identical(other.annotationLevel, annotationLevel) || other.annotationLevel == annotationLevel)&&(identical(other.message, message) || other.message == message)&&(identical(other.startColumn, startColumn) || other.startColumn == startColumn)&&(identical(other.endColumn, endColumn) || other.endColumn == endColumn)&&(identical(other.title, title) || other.title == title)&&(identical(other.rawDetails, rawDetails) || other.rawDetails == rawDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,startLine,endLine,annotationLevel,message,startColumn,endColumn,title,rawDetails);

@override
String toString() {
  return 'Annotations2(path: $path, startLine: $startLine, endLine: $endLine, annotationLevel: $annotationLevel, message: $message, startColumn: $startColumn, endColumn: $endColumn, title: $title, rawDetails: $rawDetails)';
}


}

/// @nodoc
abstract mixin class _$Annotations2CopyWith<$Res> implements $Annotations2CopyWith<$Res> {
  factory _$Annotations2CopyWith(_Annotations2 value, $Res Function(_Annotations2) _then) = __$Annotations2CopyWithImpl;
@override @useResult
$Res call({
 String path,@JsonKey(name: 'start_line') int startLine,@JsonKey(name: 'end_line') int endLine,@JsonKey(name: 'annotation_level') AnnotationLevel annotationLevel, String message,@JsonKey(name: 'start_column') int? startColumn,@JsonKey(name: 'end_column') int? endColumn, String? title,@JsonKey(name: 'raw_details') String? rawDetails
});




}
/// @nodoc
class __$Annotations2CopyWithImpl<$Res>
    implements _$Annotations2CopyWith<$Res> {
  __$Annotations2CopyWithImpl(this._self, this._then);

  final _Annotations2 _self;
  final $Res Function(_Annotations2) _then;

/// Create a copy of Annotations2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? startLine = null,Object? endLine = null,Object? annotationLevel = null,Object? message = null,Object? startColumn = freezed,Object? endColumn = freezed,Object? title = freezed,Object? rawDetails = freezed,}) {
  return _then(_Annotations2(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,startLine: null == startLine ? _self.startLine : startLine // ignore: cast_nullable_to_non_nullable
as int,endLine: null == endLine ? _self.endLine : endLine // ignore: cast_nullable_to_non_nullable
as int,annotationLevel: null == annotationLevel ? _self.annotationLevel : annotationLevel // ignore: cast_nullable_to_non_nullable
as AnnotationLevel,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,startColumn: freezed == startColumn ? _self.startColumn : startColumn // ignore: cast_nullable_to_non_nullable
as int?,endColumn: freezed == endColumn ? _self.endColumn : endColumn // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,rawDetails: freezed == rawDetails ? _self.rawDetails : rawDetails // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
