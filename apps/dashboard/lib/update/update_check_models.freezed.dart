// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_check_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateCheckState {

 LatestBuildInfo? get latest; bool get isUpdateAvailable;
/// Create a copy of UpdateCheckState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateCheckStateCopyWith<UpdateCheckState> get copyWith => _$UpdateCheckStateCopyWithImpl<UpdateCheckState>(this as UpdateCheckState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateCheckState&&(identical(other.latest, latest) || other.latest == latest)&&(identical(other.isUpdateAvailable, isUpdateAvailable) || other.isUpdateAvailable == isUpdateAvailable));
}


@override
int get hashCode => Object.hash(runtimeType,latest,isUpdateAvailable);

@override
String toString() {
  return 'UpdateCheckState(latest: $latest, isUpdateAvailable: $isUpdateAvailable)';
}


}

/// @nodoc
abstract mixin class $UpdateCheckStateCopyWith<$Res>  {
  factory $UpdateCheckStateCopyWith(UpdateCheckState value, $Res Function(UpdateCheckState) _then) = _$UpdateCheckStateCopyWithImpl;
@useResult
$Res call({
 LatestBuildInfo? latest, bool isUpdateAvailable
});


$LatestBuildInfoCopyWith<$Res>? get latest;

}
/// @nodoc
class _$UpdateCheckStateCopyWithImpl<$Res>
    implements $UpdateCheckStateCopyWith<$Res> {
  _$UpdateCheckStateCopyWithImpl(this._self, this._then);

  final UpdateCheckState _self;
  final $Res Function(UpdateCheckState) _then;

/// Create a copy of UpdateCheckState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latest = freezed,Object? isUpdateAvailable = null,}) {
  return _then(_self.copyWith(
latest: freezed == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as LatestBuildInfo?,isUpdateAvailable: null == isUpdateAvailable ? _self.isUpdateAvailable : isUpdateAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of UpdateCheckState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LatestBuildInfoCopyWith<$Res>? get latest {
    if (_self.latest == null) {
    return null;
  }

  return $LatestBuildInfoCopyWith<$Res>(_self.latest!, (value) {
    return _then(_self.copyWith(latest: value));
  });
}
}


/// Adds pattern-matching-related methods to [UpdateCheckState].
extension UpdateCheckStatePatterns on UpdateCheckState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateCheckState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateCheckState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateCheckState value)  $default,){
final _that = this;
switch (_that) {
case _UpdateCheckState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateCheckState value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateCheckState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LatestBuildInfo? latest,  bool isUpdateAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateCheckState() when $default != null:
return $default(_that.latest,_that.isUpdateAvailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LatestBuildInfo? latest,  bool isUpdateAvailable)  $default,) {final _that = this;
switch (_that) {
case _UpdateCheckState():
return $default(_that.latest,_that.isUpdateAvailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LatestBuildInfo? latest,  bool isUpdateAvailable)?  $default,) {final _that = this;
switch (_that) {
case _UpdateCheckState() when $default != null:
return $default(_that.latest,_that.isUpdateAvailable);case _:
  return null;

}
}

}

/// @nodoc


class _UpdateCheckState implements UpdateCheckState {
  const _UpdateCheckState({this.latest, this.isUpdateAvailable = false});
  

@override final  LatestBuildInfo? latest;
@override@JsonKey() final  bool isUpdateAvailable;

/// Create a copy of UpdateCheckState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateCheckStateCopyWith<_UpdateCheckState> get copyWith => __$UpdateCheckStateCopyWithImpl<_UpdateCheckState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateCheckState&&(identical(other.latest, latest) || other.latest == latest)&&(identical(other.isUpdateAvailable, isUpdateAvailable) || other.isUpdateAvailable == isUpdateAvailable));
}


@override
int get hashCode => Object.hash(runtimeType,latest,isUpdateAvailable);

@override
String toString() {
  return 'UpdateCheckState(latest: $latest, isUpdateAvailable: $isUpdateAvailable)';
}


}

/// @nodoc
abstract mixin class _$UpdateCheckStateCopyWith<$Res> implements $UpdateCheckStateCopyWith<$Res> {
  factory _$UpdateCheckStateCopyWith(_UpdateCheckState value, $Res Function(_UpdateCheckState) _then) = __$UpdateCheckStateCopyWithImpl;
@override @useResult
$Res call({
 LatestBuildInfo? latest, bool isUpdateAvailable
});


@override $LatestBuildInfoCopyWith<$Res>? get latest;

}
/// @nodoc
class __$UpdateCheckStateCopyWithImpl<$Res>
    implements _$UpdateCheckStateCopyWith<$Res> {
  __$UpdateCheckStateCopyWithImpl(this._self, this._then);

  final _UpdateCheckState _self;
  final $Res Function(_UpdateCheckState) _then;

/// Create a copy of UpdateCheckState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latest = freezed,Object? isUpdateAvailable = null,}) {
  return _then(_UpdateCheckState(
latest: freezed == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as LatestBuildInfo?,isUpdateAvailable: null == isUpdateAvailable ? _self.isUpdateAvailable : isUpdateAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of UpdateCheckState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LatestBuildInfoCopyWith<$Res>? get latest {
    if (_self.latest == null) {
    return null;
  }

  return $LatestBuildInfoCopyWith<$Res>(_self.latest!, (value) {
    return _then(_self.copyWith(latest: value));
  });
}
}


/// @nodoc
mixin _$LatestBuildInfo {

 String get version; String get sha; DateTime? get updatedAt;
/// Create a copy of LatestBuildInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LatestBuildInfoCopyWith<LatestBuildInfo> get copyWith => _$LatestBuildInfoCopyWithImpl<LatestBuildInfo>(this as LatestBuildInfo, _$identity);

  /// Serializes this LatestBuildInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LatestBuildInfo&&(identical(other.version, version) || other.version == version)&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,sha,updatedAt);

@override
String toString() {
  return 'LatestBuildInfo(version: $version, sha: $sha, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $LatestBuildInfoCopyWith<$Res>  {
  factory $LatestBuildInfoCopyWith(LatestBuildInfo value, $Res Function(LatestBuildInfo) _then) = _$LatestBuildInfoCopyWithImpl;
@useResult
$Res call({
 String version, String sha, DateTime? updatedAt
});




}
/// @nodoc
class _$LatestBuildInfoCopyWithImpl<$Res>
    implements $LatestBuildInfoCopyWith<$Res> {
  _$LatestBuildInfoCopyWithImpl(this._self, this._then);

  final LatestBuildInfo _self;
  final $Res Function(LatestBuildInfo) _then;

/// Create a copy of LatestBuildInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? sha = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LatestBuildInfo].
extension LatestBuildInfoPatterns on LatestBuildInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LatestBuildInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LatestBuildInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LatestBuildInfo value)  $default,){
final _that = this;
switch (_that) {
case _LatestBuildInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LatestBuildInfo value)?  $default,){
final _that = this;
switch (_that) {
case _LatestBuildInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String sha,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LatestBuildInfo() when $default != null:
return $default(_that.version,_that.sha,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String sha,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LatestBuildInfo():
return $default(_that.version,_that.sha,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String sha,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LatestBuildInfo() when $default != null:
return $default(_that.version,_that.sha,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LatestBuildInfo implements LatestBuildInfo {
  const _LatestBuildInfo({this.version = '', this.sha = '', this.updatedAt});
  factory _LatestBuildInfo.fromJson(Map<String, dynamic> json) => _$LatestBuildInfoFromJson(json);

@override@JsonKey() final  String version;
@override@JsonKey() final  String sha;
@override final  DateTime? updatedAt;

/// Create a copy of LatestBuildInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LatestBuildInfoCopyWith<_LatestBuildInfo> get copyWith => __$LatestBuildInfoCopyWithImpl<_LatestBuildInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LatestBuildInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LatestBuildInfo&&(identical(other.version, version) || other.version == version)&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,sha,updatedAt);

@override
String toString() {
  return 'LatestBuildInfo(version: $version, sha: $sha, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LatestBuildInfoCopyWith<$Res> implements $LatestBuildInfoCopyWith<$Res> {
  factory _$LatestBuildInfoCopyWith(_LatestBuildInfo value, $Res Function(_LatestBuildInfo) _then) = __$LatestBuildInfoCopyWithImpl;
@override @useResult
$Res call({
 String version, String sha, DateTime? updatedAt
});




}
/// @nodoc
class __$LatestBuildInfoCopyWithImpl<$Res>
    implements _$LatestBuildInfoCopyWith<$Res> {
  __$LatestBuildInfoCopyWithImpl(this._self, this._then);

  final _LatestBuildInfo _self;
  final $Res Function(_LatestBuildInfo) _then;

/// Create a copy of LatestBuildInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? sha = null,Object? updatedAt = freezed,}) {
  return _then(_LatestBuildInfo(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
