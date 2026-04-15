// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'output3.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Output3 {

 String? get title; String? get summary; String? get text;@JsonKey(name: 'annotations_count') int get annotationsCount;@JsonKey(name: 'annotations_url') String get annotationsUrl;
/// Create a copy of Output3
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Output3CopyWith<Output3> get copyWith => _$Output3CopyWithImpl<Output3>(this as Output3, _$identity);

  /// Serializes this Output3 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Output3&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.text, text) || other.text == text)&&(identical(other.annotationsCount, annotationsCount) || other.annotationsCount == annotationsCount)&&(identical(other.annotationsUrl, annotationsUrl) || other.annotationsUrl == annotationsUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,summary,text,annotationsCount,annotationsUrl);

@override
String toString() {
  return 'Output3(title: $title, summary: $summary, text: $text, annotationsCount: $annotationsCount, annotationsUrl: $annotationsUrl)';
}


}

/// @nodoc
abstract mixin class $Output3CopyWith<$Res>  {
  factory $Output3CopyWith(Output3 value, $Res Function(Output3) _then) = _$Output3CopyWithImpl;
@useResult
$Res call({
 String? title, String? summary, String? text,@JsonKey(name: 'annotations_count') int annotationsCount,@JsonKey(name: 'annotations_url') String annotationsUrl
});




}
/// @nodoc
class _$Output3CopyWithImpl<$Res>
    implements $Output3CopyWith<$Res> {
  _$Output3CopyWithImpl(this._self, this._then);

  final Output3 _self;
  final $Res Function(Output3) _then;

/// Create a copy of Output3
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? summary = freezed,Object? text = freezed,Object? annotationsCount = null,Object? annotationsUrl = null,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,annotationsCount: null == annotationsCount ? _self.annotationsCount : annotationsCount // ignore: cast_nullable_to_non_nullable
as int,annotationsUrl: null == annotationsUrl ? _self.annotationsUrl : annotationsUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Output3].
extension Output3Patterns on Output3 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Output3 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Output3() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Output3 value)  $default,){
final _that = this;
switch (_that) {
case _Output3():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Output3 value)?  $default,){
final _that = this;
switch (_that) {
case _Output3() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? summary,  String? text, @JsonKey(name: 'annotations_count')  int annotationsCount, @JsonKey(name: 'annotations_url')  String annotationsUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Output3() when $default != null:
return $default(_that.title,_that.summary,_that.text,_that.annotationsCount,_that.annotationsUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? summary,  String? text, @JsonKey(name: 'annotations_count')  int annotationsCount, @JsonKey(name: 'annotations_url')  String annotationsUrl)  $default,) {final _that = this;
switch (_that) {
case _Output3():
return $default(_that.title,_that.summary,_that.text,_that.annotationsCount,_that.annotationsUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? summary,  String? text, @JsonKey(name: 'annotations_count')  int annotationsCount, @JsonKey(name: 'annotations_url')  String annotationsUrl)?  $default,) {final _that = this;
switch (_that) {
case _Output3() when $default != null:
return $default(_that.title,_that.summary,_that.text,_that.annotationsCount,_that.annotationsUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Output3 implements Output3 {
  const _Output3({required this.title, required this.summary, required this.text, @JsonKey(name: 'annotations_count') required this.annotationsCount, @JsonKey(name: 'annotations_url') required this.annotationsUrl});
  factory _Output3.fromJson(Map<String, dynamic> json) => _$Output3FromJson(json);

@override final  String? title;
@override final  String? summary;
@override final  String? text;
@override@JsonKey(name: 'annotations_count') final  int annotationsCount;
@override@JsonKey(name: 'annotations_url') final  String annotationsUrl;

/// Create a copy of Output3
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Output3CopyWith<_Output3> get copyWith => __$Output3CopyWithImpl<_Output3>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Output3ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Output3&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.text, text) || other.text == text)&&(identical(other.annotationsCount, annotationsCount) || other.annotationsCount == annotationsCount)&&(identical(other.annotationsUrl, annotationsUrl) || other.annotationsUrl == annotationsUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,summary,text,annotationsCount,annotationsUrl);

@override
String toString() {
  return 'Output3(title: $title, summary: $summary, text: $text, annotationsCount: $annotationsCount, annotationsUrl: $annotationsUrl)';
}


}

/// @nodoc
abstract mixin class _$Output3CopyWith<$Res> implements $Output3CopyWith<$Res> {
  factory _$Output3CopyWith(_Output3 value, $Res Function(_Output3) _then) = __$Output3CopyWithImpl;
@override @useResult
$Res call({
 String? title, String? summary, String? text,@JsonKey(name: 'annotations_count') int annotationsCount,@JsonKey(name: 'annotations_url') String annotationsUrl
});




}
/// @nodoc
class __$Output3CopyWithImpl<$Res>
    implements _$Output3CopyWith<$Res> {
  __$Output3CopyWithImpl(this._self, this._then);

  final _Output3 _self;
  final $Res Function(_Output3) _then;

/// Create a copy of Output3
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? summary = freezed,Object? text = freezed,Object? annotationsCount = null,Object? annotationsUrl = null,}) {
  return _then(_Output3(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,annotationsCount: null == annotationsCount ? _self.annotationsCount : annotationsCount // ignore: cast_nullable_to_non_nullable
as int,annotationsUrl: null == annotationsUrl ? _self.annotationsUrl : annotationsUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
