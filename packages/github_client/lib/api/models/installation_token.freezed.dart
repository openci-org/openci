// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'installation_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InstallationToken {

 String get token;@JsonKey(name: 'expires_at') String get expiresAt; AppPermissions? get permissions;@JsonKey(name: 'repository_selection') InstallationTokenRepositorySelection? get repositorySelection; List<Repository>? get repositories;@JsonKey(name: 'single_file') String? get singleFile;@JsonKey(name: 'has_multiple_single_files') bool? get hasMultipleSingleFiles;@JsonKey(name: 'single_file_paths') List<String>? get singleFilePaths;
/// Create a copy of InstallationToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstallationTokenCopyWith<InstallationToken> get copyWith => _$InstallationTokenCopyWithImpl<InstallationToken>(this as InstallationToken, _$identity);

  /// Serializes this InstallationToken to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstallationToken&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.repositorySelection, repositorySelection) || other.repositorySelection == repositorySelection)&&const DeepCollectionEquality().equals(other.repositories, repositories)&&(identical(other.singleFile, singleFile) || other.singleFile == singleFile)&&(identical(other.hasMultipleSingleFiles, hasMultipleSingleFiles) || other.hasMultipleSingleFiles == hasMultipleSingleFiles)&&const DeepCollectionEquality().equals(other.singleFilePaths, singleFilePaths));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,expiresAt,permissions,repositorySelection,const DeepCollectionEquality().hash(repositories),singleFile,hasMultipleSingleFiles,const DeepCollectionEquality().hash(singleFilePaths));

@override
String toString() {
  return 'InstallationToken(token: $token, expiresAt: $expiresAt, permissions: $permissions, repositorySelection: $repositorySelection, repositories: $repositories, singleFile: $singleFile, hasMultipleSingleFiles: $hasMultipleSingleFiles, singleFilePaths: $singleFilePaths)';
}


}

/// @nodoc
abstract mixin class $InstallationTokenCopyWith<$Res>  {
  factory $InstallationTokenCopyWith(InstallationToken value, $Res Function(InstallationToken) _then) = _$InstallationTokenCopyWithImpl;
@useResult
$Res call({
 String token,@JsonKey(name: 'expires_at') String expiresAt, AppPermissions? permissions,@JsonKey(name: 'repository_selection') InstallationTokenRepositorySelection? repositorySelection, List<Repository>? repositories,@JsonKey(name: 'single_file') String? singleFile,@JsonKey(name: 'has_multiple_single_files') bool? hasMultipleSingleFiles,@JsonKey(name: 'single_file_paths') List<String>? singleFilePaths
});


$AppPermissionsCopyWith<$Res>? get permissions;

}
/// @nodoc
class _$InstallationTokenCopyWithImpl<$Res>
    implements $InstallationTokenCopyWith<$Res> {
  _$InstallationTokenCopyWithImpl(this._self, this._then);

  final InstallationToken _self;
  final $Res Function(InstallationToken) _then;

/// Create a copy of InstallationToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? expiresAt = null,Object? permissions = freezed,Object? repositorySelection = freezed,Object? repositories = freezed,Object? singleFile = freezed,Object? hasMultipleSingleFiles = freezed,Object? singleFilePaths = freezed,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,permissions: freezed == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as AppPermissions?,repositorySelection: freezed == repositorySelection ? _self.repositorySelection : repositorySelection // ignore: cast_nullable_to_non_nullable
as InstallationTokenRepositorySelection?,repositories: freezed == repositories ? _self.repositories : repositories // ignore: cast_nullable_to_non_nullable
as List<Repository>?,singleFile: freezed == singleFile ? _self.singleFile : singleFile // ignore: cast_nullable_to_non_nullable
as String?,hasMultipleSingleFiles: freezed == hasMultipleSingleFiles ? _self.hasMultipleSingleFiles : hasMultipleSingleFiles // ignore: cast_nullable_to_non_nullable
as bool?,singleFilePaths: freezed == singleFilePaths ? _self.singleFilePaths : singleFilePaths // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}
/// Create a copy of InstallationToken
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppPermissionsCopyWith<$Res>? get permissions {
    if (_self.permissions == null) {
    return null;
  }

  return $AppPermissionsCopyWith<$Res>(_self.permissions!, (value) {
    return _then(_self.copyWith(permissions: value));
  });
}
}


/// Adds pattern-matching-related methods to [InstallationToken].
extension InstallationTokenPatterns on InstallationToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstallationToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstallationToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstallationToken value)  $default,){
final _that = this;
switch (_that) {
case _InstallationToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstallationToken value)?  $default,){
final _that = this;
switch (_that) {
case _InstallationToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token, @JsonKey(name: 'expires_at')  String expiresAt,  AppPermissions? permissions, @JsonKey(name: 'repository_selection')  InstallationTokenRepositorySelection? repositorySelection,  List<Repository>? repositories, @JsonKey(name: 'single_file')  String? singleFile, @JsonKey(name: 'has_multiple_single_files')  bool? hasMultipleSingleFiles, @JsonKey(name: 'single_file_paths')  List<String>? singleFilePaths)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstallationToken() when $default != null:
return $default(_that.token,_that.expiresAt,_that.permissions,_that.repositorySelection,_that.repositories,_that.singleFile,_that.hasMultipleSingleFiles,_that.singleFilePaths);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token, @JsonKey(name: 'expires_at')  String expiresAt,  AppPermissions? permissions, @JsonKey(name: 'repository_selection')  InstallationTokenRepositorySelection? repositorySelection,  List<Repository>? repositories, @JsonKey(name: 'single_file')  String? singleFile, @JsonKey(name: 'has_multiple_single_files')  bool? hasMultipleSingleFiles, @JsonKey(name: 'single_file_paths')  List<String>? singleFilePaths)  $default,) {final _that = this;
switch (_that) {
case _InstallationToken():
return $default(_that.token,_that.expiresAt,_that.permissions,_that.repositorySelection,_that.repositories,_that.singleFile,_that.hasMultipleSingleFiles,_that.singleFilePaths);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token, @JsonKey(name: 'expires_at')  String expiresAt,  AppPermissions? permissions, @JsonKey(name: 'repository_selection')  InstallationTokenRepositorySelection? repositorySelection,  List<Repository>? repositories, @JsonKey(name: 'single_file')  String? singleFile, @JsonKey(name: 'has_multiple_single_files')  bool? hasMultipleSingleFiles, @JsonKey(name: 'single_file_paths')  List<String>? singleFilePaths)?  $default,) {final _that = this;
switch (_that) {
case _InstallationToken() when $default != null:
return $default(_that.token,_that.expiresAt,_that.permissions,_that.repositorySelection,_that.repositories,_that.singleFile,_that.hasMultipleSingleFiles,_that.singleFilePaths);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstallationToken implements InstallationToken {
  const _InstallationToken({required this.token, @JsonKey(name: 'expires_at') required this.expiresAt, this.permissions, @JsonKey(name: 'repository_selection') this.repositorySelection, final  List<Repository>? repositories, @JsonKey(name: 'single_file') this.singleFile, @JsonKey(name: 'has_multiple_single_files') this.hasMultipleSingleFiles, @JsonKey(name: 'single_file_paths') final  List<String>? singleFilePaths}): _repositories = repositories,_singleFilePaths = singleFilePaths;
  factory _InstallationToken.fromJson(Map<String, dynamic> json) => _$InstallationTokenFromJson(json);

@override final  String token;
@override@JsonKey(name: 'expires_at') final  String expiresAt;
@override final  AppPermissions? permissions;
@override@JsonKey(name: 'repository_selection') final  InstallationTokenRepositorySelection? repositorySelection;
 final  List<Repository>? _repositories;
@override List<Repository>? get repositories {
  final value = _repositories;
  if (value == null) return null;
  if (_repositories is EqualUnmodifiableListView) return _repositories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'single_file') final  String? singleFile;
@override@JsonKey(name: 'has_multiple_single_files') final  bool? hasMultipleSingleFiles;
 final  List<String>? _singleFilePaths;
@override@JsonKey(name: 'single_file_paths') List<String>? get singleFilePaths {
  final value = _singleFilePaths;
  if (value == null) return null;
  if (_singleFilePaths is EqualUnmodifiableListView) return _singleFilePaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of InstallationToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstallationTokenCopyWith<_InstallationToken> get copyWith => __$InstallationTokenCopyWithImpl<_InstallationToken>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstallationTokenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstallationToken&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.repositorySelection, repositorySelection) || other.repositorySelection == repositorySelection)&&const DeepCollectionEquality().equals(other._repositories, _repositories)&&(identical(other.singleFile, singleFile) || other.singleFile == singleFile)&&(identical(other.hasMultipleSingleFiles, hasMultipleSingleFiles) || other.hasMultipleSingleFiles == hasMultipleSingleFiles)&&const DeepCollectionEquality().equals(other._singleFilePaths, _singleFilePaths));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,expiresAt,permissions,repositorySelection,const DeepCollectionEquality().hash(_repositories),singleFile,hasMultipleSingleFiles,const DeepCollectionEquality().hash(_singleFilePaths));

@override
String toString() {
  return 'InstallationToken(token: $token, expiresAt: $expiresAt, permissions: $permissions, repositorySelection: $repositorySelection, repositories: $repositories, singleFile: $singleFile, hasMultipleSingleFiles: $hasMultipleSingleFiles, singleFilePaths: $singleFilePaths)';
}


}

/// @nodoc
abstract mixin class _$InstallationTokenCopyWith<$Res> implements $InstallationTokenCopyWith<$Res> {
  factory _$InstallationTokenCopyWith(_InstallationToken value, $Res Function(_InstallationToken) _then) = __$InstallationTokenCopyWithImpl;
@override @useResult
$Res call({
 String token,@JsonKey(name: 'expires_at') String expiresAt, AppPermissions? permissions,@JsonKey(name: 'repository_selection') InstallationTokenRepositorySelection? repositorySelection, List<Repository>? repositories,@JsonKey(name: 'single_file') String? singleFile,@JsonKey(name: 'has_multiple_single_files') bool? hasMultipleSingleFiles,@JsonKey(name: 'single_file_paths') List<String>? singleFilePaths
});


@override $AppPermissionsCopyWith<$Res>? get permissions;

}
/// @nodoc
class __$InstallationTokenCopyWithImpl<$Res>
    implements _$InstallationTokenCopyWith<$Res> {
  __$InstallationTokenCopyWithImpl(this._self, this._then);

  final _InstallationToken _self;
  final $Res Function(_InstallationToken) _then;

/// Create a copy of InstallationToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? expiresAt = null,Object? permissions = freezed,Object? repositorySelection = freezed,Object? repositories = freezed,Object? singleFile = freezed,Object? hasMultipleSingleFiles = freezed,Object? singleFilePaths = freezed,}) {
  return _then(_InstallationToken(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,permissions: freezed == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as AppPermissions?,repositorySelection: freezed == repositorySelection ? _self.repositorySelection : repositorySelection // ignore: cast_nullable_to_non_nullable
as InstallationTokenRepositorySelection?,repositories: freezed == repositories ? _self._repositories : repositories // ignore: cast_nullable_to_non_nullable
as List<Repository>?,singleFile: freezed == singleFile ? _self.singleFile : singleFile // ignore: cast_nullable_to_non_nullable
as String?,hasMultipleSingleFiles: freezed == hasMultipleSingleFiles ? _self.hasMultipleSingleFiles : hasMultipleSingleFiles // ignore: cast_nullable_to_non_nullable
as bool?,singleFilePaths: freezed == singleFilePaths ? _self._singleFilePaths : singleFilePaths // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

/// Create a copy of InstallationToken
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppPermissionsCopyWith<$Res>? get permissions {
    if (_self.permissions == null) {
    return null;
  }

  return $AppPermissionsCopyWith<$Res>(_self.permissions!, (value) {
    return _then(_self.copyWith(permissions: value));
  });
}
}

// dart format on
