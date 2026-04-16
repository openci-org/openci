// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'output.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Output {

/// The title of the check run.
 String get title;/// The summary of the check run. This parameter supports Markdown. **Maximum length**: 65535 characters.
 String get summary;/// The details of the check run. This parameter supports Markdown. **Maximum length**: 65535 characters.
 String? get text;/// Adds information from your analysis to specific lines of code. Annotations are visible on GitHub in the **Checks** and **Files changed** tab of the pull request. The Checks API limits the number of annotations to a maximum of 50 per API request. To create more than 50 annotations, you have to make multiple requests to the [Update a check run](https://docs.github.com/rest/checks/runs#update-a-check-run) endpoint. Each time you update the check run, annotations are appended to the list of annotations that already exist for the check run. GitHub Actions are limited to 10 warning annotations and 10 error annotations per step. For details about how you can view annotations on GitHub, see "[About Status checks](https://docs.github.com/articles/about-status-checks#checks)".
 List<Annotations>? get annotations;/// Adds images to the output displayed in the GitHub pull request UI.
 List<Images>? get images;
/// Create a copy of Output
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutputCopyWith<Output> get copyWith => _$OutputCopyWithImpl<Output>(this as Output, _$identity);

  /// Serializes this Output to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Output&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.annotations, annotations)&&const DeepCollectionEquality().equals(other.images, images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,summary,text,const DeepCollectionEquality().hash(annotations),const DeepCollectionEquality().hash(images));

@override
String toString() {
  return 'Output(title: $title, summary: $summary, text: $text, annotations: $annotations, images: $images)';
}


}

/// @nodoc
abstract mixin class $OutputCopyWith<$Res>  {
  factory $OutputCopyWith(Output value, $Res Function(Output) _then) = _$OutputCopyWithImpl;
@useResult
$Res call({
 String title, String summary, String? text, List<Annotations>? annotations, List<Images>? images
});




}
/// @nodoc
class _$OutputCopyWithImpl<$Res>
    implements $OutputCopyWith<$Res> {
  _$OutputCopyWithImpl(this._self, this._then);

  final Output _self;
  final $Res Function(Output) _then;

/// Create a copy of Output
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? summary = null,Object? text = freezed,Object? annotations = freezed,Object? images = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,annotations: freezed == annotations ? _self.annotations : annotations // ignore: cast_nullable_to_non_nullable
as List<Annotations>?,images: freezed == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<Images>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Output].
extension OutputPatterns on Output {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Output value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Output() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Output value)  $default,){
final _that = this;
switch (_that) {
case _Output():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Output value)?  $default,){
final _that = this;
switch (_that) {
case _Output() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String summary,  String? text,  List<Annotations>? annotations,  List<Images>? images)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Output() when $default != null:
return $default(_that.title,_that.summary,_that.text,_that.annotations,_that.images);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String summary,  String? text,  List<Annotations>? annotations,  List<Images>? images)  $default,) {final _that = this;
switch (_that) {
case _Output():
return $default(_that.title,_that.summary,_that.text,_that.annotations,_that.images);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String summary,  String? text,  List<Annotations>? annotations,  List<Images>? images)?  $default,) {final _that = this;
switch (_that) {
case _Output() when $default != null:
return $default(_that.title,_that.summary,_that.text,_that.annotations,_that.images);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Output implements Output {
  const _Output({required this.title, required this.summary, this.text, final  List<Annotations>? annotations, final  List<Images>? images}): _annotations = annotations,_images = images;
  factory _Output.fromJson(Map<String, dynamic> json) => _$OutputFromJson(json);

/// The title of the check run.
@override final  String title;
/// The summary of the check run. This parameter supports Markdown. **Maximum length**: 65535 characters.
@override final  String summary;
/// The details of the check run. This parameter supports Markdown. **Maximum length**: 65535 characters.
@override final  String? text;
/// Adds information from your analysis to specific lines of code. Annotations are visible on GitHub in the **Checks** and **Files changed** tab of the pull request. The Checks API limits the number of annotations to a maximum of 50 per API request. To create more than 50 annotations, you have to make multiple requests to the [Update a check run](https://docs.github.com/rest/checks/runs#update-a-check-run) endpoint. Each time you update the check run, annotations are appended to the list of annotations that already exist for the check run. GitHub Actions are limited to 10 warning annotations and 10 error annotations per step. For details about how you can view annotations on GitHub, see "[About Status checks](https://docs.github.com/articles/about-status-checks#checks)".
 final  List<Annotations>? _annotations;
/// Adds information from your analysis to specific lines of code. Annotations are visible on GitHub in the **Checks** and **Files changed** tab of the pull request. The Checks API limits the number of annotations to a maximum of 50 per API request. To create more than 50 annotations, you have to make multiple requests to the [Update a check run](https://docs.github.com/rest/checks/runs#update-a-check-run) endpoint. Each time you update the check run, annotations are appended to the list of annotations that already exist for the check run. GitHub Actions are limited to 10 warning annotations and 10 error annotations per step. For details about how you can view annotations on GitHub, see "[About Status checks](https://docs.github.com/articles/about-status-checks#checks)".
@override List<Annotations>? get annotations {
  final value = _annotations;
  if (value == null) return null;
  if (_annotations is EqualUnmodifiableListView) return _annotations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Adds images to the output displayed in the GitHub pull request UI.
 final  List<Images>? _images;
/// Adds images to the output displayed in the GitHub pull request UI.
@override List<Images>? get images {
  final value = _images;
  if (value == null) return null;
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Output
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutputCopyWith<_Output> get copyWith => __$OutputCopyWithImpl<_Output>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutputToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Output&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._annotations, _annotations)&&const DeepCollectionEquality().equals(other._images, _images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,summary,text,const DeepCollectionEquality().hash(_annotations),const DeepCollectionEquality().hash(_images));

@override
String toString() {
  return 'Output(title: $title, summary: $summary, text: $text, annotations: $annotations, images: $images)';
}


}

/// @nodoc
abstract mixin class _$OutputCopyWith<$Res> implements $OutputCopyWith<$Res> {
  factory _$OutputCopyWith(_Output value, $Res Function(_Output) _then) = __$OutputCopyWithImpl;
@override @useResult
$Res call({
 String title, String summary, String? text, List<Annotations>? annotations, List<Images>? images
});




}
/// @nodoc
class __$OutputCopyWithImpl<$Res>
    implements _$OutputCopyWith<$Res> {
  __$OutputCopyWithImpl(this._self, this._then);

  final _Output _self;
  final $Res Function(_Output) _then;

/// Create a copy of Output
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? summary = null,Object? text = freezed,Object? annotations = freezed,Object? images = freezed,}) {
  return _then(_Output(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,annotations: freezed == annotations ? _self._annotations : annotations // ignore: cast_nullable_to_non_nullable
as List<Annotations>?,images: freezed == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<Images>?,
  ));
}


}

// dart format on
