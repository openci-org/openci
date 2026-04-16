// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'code_of_conduct_simple.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CodeOfConductSimple {

 String get url;@JsonKey(name: 'Key') String get key; String get name;@JsonKey(name: 'html_url') String? get htmlUrl;
/// Create a copy of CodeOfConductSimple
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodeOfConductSimpleCopyWith<CodeOfConductSimple> get copyWith => _$CodeOfConductSimpleCopyWithImpl<CodeOfConductSimple>(this as CodeOfConductSimple, _$identity);

  /// Serializes this CodeOfConductSimple to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeOfConductSimple&&(identical(other.url, url) || other.url == url)&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,key,name,htmlUrl);

@override
String toString() {
  return 'CodeOfConductSimple(url: $url, key: $key, name: $name, htmlUrl: $htmlUrl)';
}


}

/// @nodoc
abstract mixin class $CodeOfConductSimpleCopyWith<$Res>  {
  factory $CodeOfConductSimpleCopyWith(CodeOfConductSimple value, $Res Function(CodeOfConductSimple) _then) = _$CodeOfConductSimpleCopyWithImpl;
@useResult
$Res call({
 String url,@JsonKey(name: 'Key') String key, String name,@JsonKey(name: 'html_url') String? htmlUrl
});




}
/// @nodoc
class _$CodeOfConductSimpleCopyWithImpl<$Res>
    implements $CodeOfConductSimpleCopyWith<$Res> {
  _$CodeOfConductSimpleCopyWithImpl(this._self, this._then);

  final CodeOfConductSimple _self;
  final $Res Function(CodeOfConductSimple) _then;

/// Create a copy of CodeOfConductSimple
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? key = null,Object? name = null,Object? htmlUrl = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CodeOfConductSimple].
extension CodeOfConductSimplePatterns on CodeOfConductSimple {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CodeOfConductSimple value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CodeOfConductSimple() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CodeOfConductSimple value)  $default,){
final _that = this;
switch (_that) {
case _CodeOfConductSimple():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CodeOfConductSimple value)?  $default,){
final _that = this;
switch (_that) {
case _CodeOfConductSimple() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url, @JsonKey(name: 'Key')  String key,  String name, @JsonKey(name: 'html_url')  String? htmlUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CodeOfConductSimple() when $default != null:
return $default(_that.url,_that.key,_that.name,_that.htmlUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url, @JsonKey(name: 'Key')  String key,  String name, @JsonKey(name: 'html_url')  String? htmlUrl)  $default,) {final _that = this;
switch (_that) {
case _CodeOfConductSimple():
return $default(_that.url,_that.key,_that.name,_that.htmlUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url, @JsonKey(name: 'Key')  String key,  String name, @JsonKey(name: 'html_url')  String? htmlUrl)?  $default,) {final _that = this;
switch (_that) {
case _CodeOfConductSimple() when $default != null:
return $default(_that.url,_that.key,_that.name,_that.htmlUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CodeOfConductSimple implements CodeOfConductSimple {
  const _CodeOfConductSimple({required this.url, @JsonKey(name: 'Key') required this.key, required this.name, @JsonKey(name: 'html_url') required this.htmlUrl});
  factory _CodeOfConductSimple.fromJson(Map<String, dynamic> json) => _$CodeOfConductSimpleFromJson(json);

@override final  String url;
@override@JsonKey(name: 'Key') final  String key;
@override final  String name;
@override@JsonKey(name: 'html_url') final  String? htmlUrl;

/// Create a copy of CodeOfConductSimple
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CodeOfConductSimpleCopyWith<_CodeOfConductSimple> get copyWith => __$CodeOfConductSimpleCopyWithImpl<_CodeOfConductSimple>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CodeOfConductSimpleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CodeOfConductSimple&&(identical(other.url, url) || other.url == url)&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,key,name,htmlUrl);

@override
String toString() {
  return 'CodeOfConductSimple(url: $url, key: $key, name: $name, htmlUrl: $htmlUrl)';
}


}

/// @nodoc
abstract mixin class _$CodeOfConductSimpleCopyWith<$Res> implements $CodeOfConductSimpleCopyWith<$Res> {
  factory _$CodeOfConductSimpleCopyWith(_CodeOfConductSimple value, $Res Function(_CodeOfConductSimple) _then) = __$CodeOfConductSimpleCopyWithImpl;
@override @useResult
$Res call({
 String url,@JsonKey(name: 'Key') String key, String name,@JsonKey(name: 'html_url') String? htmlUrl
});




}
/// @nodoc
class __$CodeOfConductSimpleCopyWithImpl<$Res>
    implements _$CodeOfConductSimpleCopyWith<$Res> {
  __$CodeOfConductSimpleCopyWithImpl(this._self, this._then);

  final _CodeOfConductSimple _self;
  final $Res Function(_CodeOfConductSimple) _then;

/// Create a copy of CodeOfConductSimple
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? key = null,Object? name = null,Object? htmlUrl = freezed,}) {
  return _then(_CodeOfConductSimple(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
