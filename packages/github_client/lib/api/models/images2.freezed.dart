// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'images2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Images2 {

/// The alternative text for the image.
 String get alt;/// The full URL of the image.
@JsonKey(name: 'image_url') String get imageUrl;/// A short image description.
 String? get caption;
/// Create a copy of Images2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Images2CopyWith<Images2> get copyWith => _$Images2CopyWithImpl<Images2>(this as Images2, _$identity);

  /// Serializes this Images2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Images2&&(identical(other.alt, alt) || other.alt == alt)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.caption, caption) || other.caption == caption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,alt,imageUrl,caption);

@override
String toString() {
  return 'Images2(alt: $alt, imageUrl: $imageUrl, caption: $caption)';
}


}

/// @nodoc
abstract mixin class $Images2CopyWith<$Res>  {
  factory $Images2CopyWith(Images2 value, $Res Function(Images2) _then) = _$Images2CopyWithImpl;
@useResult
$Res call({
 String alt,@JsonKey(name: 'image_url') String imageUrl, String? caption
});




}
/// @nodoc
class _$Images2CopyWithImpl<$Res>
    implements $Images2CopyWith<$Res> {
  _$Images2CopyWithImpl(this._self, this._then);

  final Images2 _self;
  final $Res Function(Images2) _then;

/// Create a copy of Images2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? alt = null,Object? imageUrl = null,Object? caption = freezed,}) {
  return _then(_self.copyWith(
alt: null == alt ? _self.alt : alt // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Images2].
extension Images2Patterns on Images2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Images2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Images2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Images2 value)  $default,){
final _that = this;
switch (_that) {
case _Images2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Images2 value)?  $default,){
final _that = this;
switch (_that) {
case _Images2() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String alt, @JsonKey(name: 'image_url')  String imageUrl,  String? caption)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Images2() when $default != null:
return $default(_that.alt,_that.imageUrl,_that.caption);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String alt, @JsonKey(name: 'image_url')  String imageUrl,  String? caption)  $default,) {final _that = this;
switch (_that) {
case _Images2():
return $default(_that.alt,_that.imageUrl,_that.caption);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String alt, @JsonKey(name: 'image_url')  String imageUrl,  String? caption)?  $default,) {final _that = this;
switch (_that) {
case _Images2() when $default != null:
return $default(_that.alt,_that.imageUrl,_that.caption);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Images2 implements Images2 {
  const _Images2({required this.alt, @JsonKey(name: 'image_url') required this.imageUrl, this.caption});
  factory _Images2.fromJson(Map<String, dynamic> json) => _$Images2FromJson(json);

/// The alternative text for the image.
@override final  String alt;
/// The full URL of the image.
@override@JsonKey(name: 'image_url') final  String imageUrl;
/// A short image description.
@override final  String? caption;

/// Create a copy of Images2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Images2CopyWith<_Images2> get copyWith => __$Images2CopyWithImpl<_Images2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Images2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Images2&&(identical(other.alt, alt) || other.alt == alt)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.caption, caption) || other.caption == caption));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,alt,imageUrl,caption);

@override
String toString() {
  return 'Images2(alt: $alt, imageUrl: $imageUrl, caption: $caption)';
}


}

/// @nodoc
abstract mixin class _$Images2CopyWith<$Res> implements $Images2CopyWith<$Res> {
  factory _$Images2CopyWith(_Images2 value, $Res Function(_Images2) _then) = __$Images2CopyWithImpl;
@override @useResult
$Res call({
 String alt,@JsonKey(name: 'image_url') String imageUrl, String? caption
});




}
/// @nodoc
class __$Images2CopyWithImpl<$Res>
    implements _$Images2CopyWith<$Res> {
  __$Images2CopyWithImpl(this._self, this._then);

  final _Images2 _self;
  final $Res Function(_Images2) _then;

/// Create a copy of Images2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? alt = null,Object? imageUrl = null,Object? caption = freezed,}) {
  return _then(_Images2(
alt: null == alt ? _self.alt : alt // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
