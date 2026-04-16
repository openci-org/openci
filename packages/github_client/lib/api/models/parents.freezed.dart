// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parents.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Parents {

 String get sha; String get url;@JsonKey(name: 'html_url') String? get htmlUrl;
/// Create a copy of Parents
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParentsCopyWith<Parents> get copyWith => _$ParentsCopyWithImpl<Parents>(this as Parents, _$identity);

  /// Serializes this Parents to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Parents&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.url, url) || other.url == url)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sha,url,htmlUrl);

@override
String toString() {
  return 'Parents(sha: $sha, url: $url, htmlUrl: $htmlUrl)';
}


}

/// @nodoc
abstract mixin class $ParentsCopyWith<$Res>  {
  factory $ParentsCopyWith(Parents value, $Res Function(Parents) _then) = _$ParentsCopyWithImpl;
@useResult
$Res call({
 String sha, String url,@JsonKey(name: 'html_url') String? htmlUrl
});




}
/// @nodoc
class _$ParentsCopyWithImpl<$Res>
    implements $ParentsCopyWith<$Res> {
  _$ParentsCopyWithImpl(this._self, this._then);

  final Parents _self;
  final $Res Function(Parents) _then;

/// Create a copy of Parents
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sha = null,Object? url = null,Object? htmlUrl = freezed,}) {
  return _then(_self.copyWith(
sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Parents].
extension ParentsPatterns on Parents {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Parents value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Parents() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Parents value)  $default,){
final _that = this;
switch (_that) {
case _Parents():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Parents value)?  $default,){
final _that = this;
switch (_that) {
case _Parents() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sha,  String url, @JsonKey(name: 'html_url')  String? htmlUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Parents() when $default != null:
return $default(_that.sha,_that.url,_that.htmlUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sha,  String url, @JsonKey(name: 'html_url')  String? htmlUrl)  $default,) {final _that = this;
switch (_that) {
case _Parents():
return $default(_that.sha,_that.url,_that.htmlUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sha,  String url, @JsonKey(name: 'html_url')  String? htmlUrl)?  $default,) {final _that = this;
switch (_that) {
case _Parents() when $default != null:
return $default(_that.sha,_that.url,_that.htmlUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Parents implements Parents {
  const _Parents({required this.sha, required this.url, @JsonKey(name: 'html_url') this.htmlUrl});
  factory _Parents.fromJson(Map<String, dynamic> json) => _$ParentsFromJson(json);

@override final  String sha;
@override final  String url;
@override@JsonKey(name: 'html_url') final  String? htmlUrl;

/// Create a copy of Parents
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParentsCopyWith<_Parents> get copyWith => __$ParentsCopyWithImpl<_Parents>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParentsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Parents&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.url, url) || other.url == url)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sha,url,htmlUrl);

@override
String toString() {
  return 'Parents(sha: $sha, url: $url, htmlUrl: $htmlUrl)';
}


}

/// @nodoc
abstract mixin class _$ParentsCopyWith<$Res> implements $ParentsCopyWith<$Res> {
  factory _$ParentsCopyWith(_Parents value, $Res Function(_Parents) _then) = __$ParentsCopyWithImpl;
@override @useResult
$Res call({
 String sha, String url,@JsonKey(name: 'html_url') String? htmlUrl
});




}
/// @nodoc
class __$ParentsCopyWithImpl<$Res>
    implements _$ParentsCopyWith<$Res> {
  __$ParentsCopyWithImpl(this._self, this._then);

  final _Parents _self;
  final $Res Function(_Parents) _then;

/// Create a copy of Parents
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sha = null,Object? url = null,Object? htmlUrl = freezed,}) {
  return _then(_Parents(
sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
