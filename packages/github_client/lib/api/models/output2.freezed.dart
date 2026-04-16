// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'output2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Output2 {

/// Can contain Markdown.
 String get summary;/// **Required**.
 String? get title;/// Can contain Markdown.
 String? get text;/// Adds information from your analysis to specific lines of code. Annotations are visible in GitHub's pull request UI. Annotations are visible in GitHub's pull request UI. The Checks API limits the number of annotations to a maximum of 50 per API request. To create more than 50 annotations, you have to make multiple requests to the [Update a check run](https://docs.github.com/rest/checks/runs#update-a-check-run) endpoint. Each time you update the check run, annotations are appended to the list of annotations that already exist for the check run. GitHub Actions are limited to 10 warning annotations and 10 error annotations per step. For details about annotations in the UI, see "[About Status checks](https://docs.github.com/articles/about-status-checks#checks)".
 List<Annotations2>? get annotations;/// Adds images to the output displayed in the GitHub pull request UI.
 List<Images2>? get images;
/// Create a copy of Output2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Output2CopyWith<Output2> get copyWith => _$Output2CopyWithImpl<Output2>(this as Output2, _$identity);

  /// Serializes this Output2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Output2&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.annotations, annotations)&&const DeepCollectionEquality().equals(other.images, images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,title,text,const DeepCollectionEquality().hash(annotations),const DeepCollectionEquality().hash(images));

@override
String toString() {
  return 'Output2(summary: $summary, title: $title, text: $text, annotations: $annotations, images: $images)';
}


}

/// @nodoc
abstract mixin class $Output2CopyWith<$Res>  {
  factory $Output2CopyWith(Output2 value, $Res Function(Output2) _then) = _$Output2CopyWithImpl;
@useResult
$Res call({
 String summary, String? title, String? text, List<Annotations2>? annotations, List<Images2>? images
});




}
/// @nodoc
class _$Output2CopyWithImpl<$Res>
    implements $Output2CopyWith<$Res> {
  _$Output2CopyWithImpl(this._self, this._then);

  final Output2 _self;
  final $Res Function(Output2) _then;

/// Create a copy of Output2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? title = freezed,Object? text = freezed,Object? annotations = freezed,Object? images = freezed,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,annotations: freezed == annotations ? _self.annotations : annotations // ignore: cast_nullable_to_non_nullable
as List<Annotations2>?,images: freezed == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<Images2>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Output2].
extension Output2Patterns on Output2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Output2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Output2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Output2 value)  $default,){
final _that = this;
switch (_that) {
case _Output2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Output2 value)?  $default,){
final _that = this;
switch (_that) {
case _Output2() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String summary,  String? title,  String? text,  List<Annotations2>? annotations,  List<Images2>? images)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Output2() when $default != null:
return $default(_that.summary,_that.title,_that.text,_that.annotations,_that.images);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String summary,  String? title,  String? text,  List<Annotations2>? annotations,  List<Images2>? images)  $default,) {final _that = this;
switch (_that) {
case _Output2():
return $default(_that.summary,_that.title,_that.text,_that.annotations,_that.images);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String summary,  String? title,  String? text,  List<Annotations2>? annotations,  List<Images2>? images)?  $default,) {final _that = this;
switch (_that) {
case _Output2() when $default != null:
return $default(_that.summary,_that.title,_that.text,_that.annotations,_that.images);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Output2 implements Output2 {
  const _Output2({required this.summary, this.title, this.text, final  List<Annotations2>? annotations, final  List<Images2>? images}): _annotations = annotations,_images = images;
  factory _Output2.fromJson(Map<String, dynamic> json) => _$Output2FromJson(json);

/// Can contain Markdown.
@override final  String summary;
/// **Required**.
@override final  String? title;
/// Can contain Markdown.
@override final  String? text;
/// Adds information from your analysis to specific lines of code. Annotations are visible in GitHub's pull request UI. Annotations are visible in GitHub's pull request UI. The Checks API limits the number of annotations to a maximum of 50 per API request. To create more than 50 annotations, you have to make multiple requests to the [Update a check run](https://docs.github.com/rest/checks/runs#update-a-check-run) endpoint. Each time you update the check run, annotations are appended to the list of annotations that already exist for the check run. GitHub Actions are limited to 10 warning annotations and 10 error annotations per step. For details about annotations in the UI, see "[About Status checks](https://docs.github.com/articles/about-status-checks#checks)".
 final  List<Annotations2>? _annotations;
/// Adds information from your analysis to specific lines of code. Annotations are visible in GitHub's pull request UI. Annotations are visible in GitHub's pull request UI. The Checks API limits the number of annotations to a maximum of 50 per API request. To create more than 50 annotations, you have to make multiple requests to the [Update a check run](https://docs.github.com/rest/checks/runs#update-a-check-run) endpoint. Each time you update the check run, annotations are appended to the list of annotations that already exist for the check run. GitHub Actions are limited to 10 warning annotations and 10 error annotations per step. For details about annotations in the UI, see "[About Status checks](https://docs.github.com/articles/about-status-checks#checks)".
@override List<Annotations2>? get annotations {
  final value = _annotations;
  if (value == null) return null;
  if (_annotations is EqualUnmodifiableListView) return _annotations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Adds images to the output displayed in the GitHub pull request UI.
 final  List<Images2>? _images;
/// Adds images to the output displayed in the GitHub pull request UI.
@override List<Images2>? get images {
  final value = _images;
  if (value == null) return null;
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Output2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Output2CopyWith<_Output2> get copyWith => __$Output2CopyWithImpl<_Output2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Output2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Output2&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._annotations, _annotations)&&const DeepCollectionEquality().equals(other._images, _images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,title,text,const DeepCollectionEquality().hash(_annotations),const DeepCollectionEquality().hash(_images));

@override
String toString() {
  return 'Output2(summary: $summary, title: $title, text: $text, annotations: $annotations, images: $images)';
}


}

/// @nodoc
abstract mixin class _$Output2CopyWith<$Res> implements $Output2CopyWith<$Res> {
  factory _$Output2CopyWith(_Output2 value, $Res Function(_Output2) _then) = __$Output2CopyWithImpl;
@override @useResult
$Res call({
 String summary, String? title, String? text, List<Annotations2>? annotations, List<Images2>? images
});




}
/// @nodoc
class __$Output2CopyWithImpl<$Res>
    implements _$Output2CopyWith<$Res> {
  __$Output2CopyWithImpl(this._self, this._then);

  final _Output2 _self;
  final $Res Function(_Output2) _then;

/// Create a copy of Output2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? title = freezed,Object? text = freezed,Object? annotations = freezed,Object? images = freezed,}) {
  return _then(_Output2(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,annotations: freezed == annotations ? _self._annotations : annotations // ignore: cast_nullable_to_non_nullable
as List<Annotations2>?,images: freezed == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<Images2>?,
  ));
}


}

// dart format on
