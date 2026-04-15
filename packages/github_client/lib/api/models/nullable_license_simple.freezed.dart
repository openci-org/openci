// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nullable_license_simple.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NullableLicenseSimple {

@JsonKey(name: 'Key') String get key; String get name; String? get url;@JsonKey(name: 'spdx_id') String? get spdxId;@JsonKey(name: 'node_id') String get nodeId;@JsonKey(name: 'html_url') String? get htmlUrl;
/// Create a copy of NullableLicenseSimple
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NullableLicenseSimpleCopyWith<NullableLicenseSimple> get copyWith => _$NullableLicenseSimpleCopyWithImpl<NullableLicenseSimple>(this as NullableLicenseSimple, _$identity);

  /// Serializes this NullableLicenseSimple to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NullableLicenseSimple&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.spdxId, spdxId) || other.spdxId == spdxId)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,name,url,spdxId,nodeId,htmlUrl);

@override
String toString() {
  return 'NullableLicenseSimple(key: $key, name: $name, url: $url, spdxId: $spdxId, nodeId: $nodeId, htmlUrl: $htmlUrl)';
}


}

/// @nodoc
abstract mixin class $NullableLicenseSimpleCopyWith<$Res>  {
  factory $NullableLicenseSimpleCopyWith(NullableLicenseSimple value, $Res Function(NullableLicenseSimple) _then) = _$NullableLicenseSimpleCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Key') String key, String name, String? url,@JsonKey(name: 'spdx_id') String? spdxId,@JsonKey(name: 'node_id') String nodeId,@JsonKey(name: 'html_url') String? htmlUrl
});




}
/// @nodoc
class _$NullableLicenseSimpleCopyWithImpl<$Res>
    implements $NullableLicenseSimpleCopyWith<$Res> {
  _$NullableLicenseSimpleCopyWithImpl(this._self, this._then);

  final NullableLicenseSimple _self;
  final $Res Function(NullableLicenseSimple) _then;

/// Create a copy of NullableLicenseSimple
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? name = null,Object? url = freezed,Object? spdxId = freezed,Object? nodeId = null,Object? htmlUrl = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,spdxId: freezed == spdxId ? _self.spdxId : spdxId // ignore: cast_nullable_to_non_nullable
as String?,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NullableLicenseSimple].
extension NullableLicenseSimplePatterns on NullableLicenseSimple {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NullableLicenseSimple value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NullableLicenseSimple() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NullableLicenseSimple value)  $default,){
final _that = this;
switch (_that) {
case _NullableLicenseSimple():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NullableLicenseSimple value)?  $default,){
final _that = this;
switch (_that) {
case _NullableLicenseSimple() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Key')  String key,  String name,  String? url, @JsonKey(name: 'spdx_id')  String? spdxId, @JsonKey(name: 'node_id')  String nodeId, @JsonKey(name: 'html_url')  String? htmlUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NullableLicenseSimple() when $default != null:
return $default(_that.key,_that.name,_that.url,_that.spdxId,_that.nodeId,_that.htmlUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Key')  String key,  String name,  String? url, @JsonKey(name: 'spdx_id')  String? spdxId, @JsonKey(name: 'node_id')  String nodeId, @JsonKey(name: 'html_url')  String? htmlUrl)  $default,) {final _that = this;
switch (_that) {
case _NullableLicenseSimple():
return $default(_that.key,_that.name,_that.url,_that.spdxId,_that.nodeId,_that.htmlUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Key')  String key,  String name,  String? url, @JsonKey(name: 'spdx_id')  String? spdxId, @JsonKey(name: 'node_id')  String nodeId, @JsonKey(name: 'html_url')  String? htmlUrl)?  $default,) {final _that = this;
switch (_that) {
case _NullableLicenseSimple() when $default != null:
return $default(_that.key,_that.name,_that.url,_that.spdxId,_that.nodeId,_that.htmlUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NullableLicenseSimple implements NullableLicenseSimple {
  const _NullableLicenseSimple({@JsonKey(name: 'Key') required this.key, required this.name, required this.url, @JsonKey(name: 'spdx_id') required this.spdxId, @JsonKey(name: 'node_id') required this.nodeId, @JsonKey(name: 'html_url') this.htmlUrl});
  factory _NullableLicenseSimple.fromJson(Map<String, dynamic> json) => _$NullableLicenseSimpleFromJson(json);

@override@JsonKey(name: 'Key') final  String key;
@override final  String name;
@override final  String? url;
@override@JsonKey(name: 'spdx_id') final  String? spdxId;
@override@JsonKey(name: 'node_id') final  String nodeId;
@override@JsonKey(name: 'html_url') final  String? htmlUrl;

/// Create a copy of NullableLicenseSimple
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NullableLicenseSimpleCopyWith<_NullableLicenseSimple> get copyWith => __$NullableLicenseSimpleCopyWithImpl<_NullableLicenseSimple>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NullableLicenseSimpleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NullableLicenseSimple&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.spdxId, spdxId) || other.spdxId == spdxId)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,name,url,spdxId,nodeId,htmlUrl);

@override
String toString() {
  return 'NullableLicenseSimple(key: $key, name: $name, url: $url, spdxId: $spdxId, nodeId: $nodeId, htmlUrl: $htmlUrl)';
}


}

/// @nodoc
abstract mixin class _$NullableLicenseSimpleCopyWith<$Res> implements $NullableLicenseSimpleCopyWith<$Res> {
  factory _$NullableLicenseSimpleCopyWith(_NullableLicenseSimple value, $Res Function(_NullableLicenseSimple) _then) = __$NullableLicenseSimpleCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Key') String key, String name, String? url,@JsonKey(name: 'spdx_id') String? spdxId,@JsonKey(name: 'node_id') String nodeId,@JsonKey(name: 'html_url') String? htmlUrl
});




}
/// @nodoc
class __$NullableLicenseSimpleCopyWithImpl<$Res>
    implements _$NullableLicenseSimpleCopyWith<$Res> {
  __$NullableLicenseSimpleCopyWithImpl(this._self, this._then);

  final _NullableLicenseSimple _self;
  final $Res Function(_NullableLicenseSimple) _then;

/// Create a copy of NullableLicenseSimple
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? name = null,Object? url = freezed,Object? spdxId = freezed,Object? nodeId = null,Object? htmlUrl = freezed,}) {
  return _then(_NullableLicenseSimple(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,spdxId: freezed == spdxId ? _self.spdxId : spdxId // ignore: cast_nullable_to_non_nullable
as String?,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
