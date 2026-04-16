// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_installations_installation_id_access_tokens_request_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppInstallationsInstallationIdAccessTokensRequestBody {

/// List of Repository names that the token should have access to
 List<String>? get repositories;/// List of Repository IDs that the token should have access to
@JsonKey(name: 'repository_ids') List<int>? get repositoryIds; AppPermissions? get permissions;
/// Create a copy of AppInstallationsInstallationIdAccessTokensRequestBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWith<AppInstallationsInstallationIdAccessTokensRequestBody> get copyWith => _$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWithImpl<AppInstallationsInstallationIdAccessTokensRequestBody>(this as AppInstallationsInstallationIdAccessTokensRequestBody, _$identity);

  /// Serializes this AppInstallationsInstallationIdAccessTokensRequestBody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppInstallationsInstallationIdAccessTokensRequestBody&&const DeepCollectionEquality().equals(other.repositories, repositories)&&const DeepCollectionEquality().equals(other.repositoryIds, repositoryIds)&&(identical(other.permissions, permissions) || other.permissions == permissions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(repositories),const DeepCollectionEquality().hash(repositoryIds),permissions);

@override
String toString() {
  return 'AppInstallationsInstallationIdAccessTokensRequestBody(repositories: $repositories, repositoryIds: $repositoryIds, permissions: $permissions)';
}


}

/// @nodoc
abstract mixin class $AppInstallationsInstallationIdAccessTokensRequestBodyCopyWith<$Res>  {
  factory $AppInstallationsInstallationIdAccessTokensRequestBodyCopyWith(AppInstallationsInstallationIdAccessTokensRequestBody value, $Res Function(AppInstallationsInstallationIdAccessTokensRequestBody) _then) = _$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWithImpl;
@useResult
$Res call({
 List<String>? repositories,@JsonKey(name: 'repository_ids') List<int>? repositoryIds, AppPermissions? permissions
});


$AppPermissionsCopyWith<$Res>? get permissions;

}
/// @nodoc
class _$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWithImpl<$Res>
    implements $AppInstallationsInstallationIdAccessTokensRequestBodyCopyWith<$Res> {
  _$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWithImpl(this._self, this._then);

  final AppInstallationsInstallationIdAccessTokensRequestBody _self;
  final $Res Function(AppInstallationsInstallationIdAccessTokensRequestBody) _then;

/// Create a copy of AppInstallationsInstallationIdAccessTokensRequestBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? repositories = freezed,Object? repositoryIds = freezed,Object? permissions = freezed,}) {
  return _then(_self.copyWith(
repositories: freezed == repositories ? _self.repositories : repositories // ignore: cast_nullable_to_non_nullable
as List<String>?,repositoryIds: freezed == repositoryIds ? _self.repositoryIds : repositoryIds // ignore: cast_nullable_to_non_nullable
as List<int>?,permissions: freezed == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as AppPermissions?,
  ));
}
/// Create a copy of AppInstallationsInstallationIdAccessTokensRequestBody
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


/// Adds pattern-matching-related methods to [AppInstallationsInstallationIdAccessTokensRequestBody].
extension AppInstallationsInstallationIdAccessTokensRequestBodyPatterns on AppInstallationsInstallationIdAccessTokensRequestBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppInstallationsInstallationIdAccessTokensRequestBody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppInstallationsInstallationIdAccessTokensRequestBody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppInstallationsInstallationIdAccessTokensRequestBody value)  $default,){
final _that = this;
switch (_that) {
case _AppInstallationsInstallationIdAccessTokensRequestBody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppInstallationsInstallationIdAccessTokensRequestBody value)?  $default,){
final _that = this;
switch (_that) {
case _AppInstallationsInstallationIdAccessTokensRequestBody() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String>? repositories, @JsonKey(name: 'repository_ids')  List<int>? repositoryIds,  AppPermissions? permissions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppInstallationsInstallationIdAccessTokensRequestBody() when $default != null:
return $default(_that.repositories,_that.repositoryIds,_that.permissions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String>? repositories, @JsonKey(name: 'repository_ids')  List<int>? repositoryIds,  AppPermissions? permissions)  $default,) {final _that = this;
switch (_that) {
case _AppInstallationsInstallationIdAccessTokensRequestBody():
return $default(_that.repositories,_that.repositoryIds,_that.permissions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String>? repositories, @JsonKey(name: 'repository_ids')  List<int>? repositoryIds,  AppPermissions? permissions)?  $default,) {final _that = this;
switch (_that) {
case _AppInstallationsInstallationIdAccessTokensRequestBody() when $default != null:
return $default(_that.repositories,_that.repositoryIds,_that.permissions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppInstallationsInstallationIdAccessTokensRequestBody implements AppInstallationsInstallationIdAccessTokensRequestBody {
  const _AppInstallationsInstallationIdAccessTokensRequestBody({final  List<String>? repositories, @JsonKey(name: 'repository_ids') final  List<int>? repositoryIds, this.permissions}): _repositories = repositories,_repositoryIds = repositoryIds;
  factory _AppInstallationsInstallationIdAccessTokensRequestBody.fromJson(Map<String, dynamic> json) => _$AppInstallationsInstallationIdAccessTokensRequestBodyFromJson(json);

/// List of Repository names that the token should have access to
 final  List<String>? _repositories;
/// List of Repository names that the token should have access to
@override List<String>? get repositories {
  final value = _repositories;
  if (value == null) return null;
  if (_repositories is EqualUnmodifiableListView) return _repositories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// List of Repository IDs that the token should have access to
 final  List<int>? _repositoryIds;
/// List of Repository IDs that the token should have access to
@override@JsonKey(name: 'repository_ids') List<int>? get repositoryIds {
  final value = _repositoryIds;
  if (value == null) return null;
  if (_repositoryIds is EqualUnmodifiableListView) return _repositoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  AppPermissions? permissions;

/// Create a copy of AppInstallationsInstallationIdAccessTokensRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWith<_AppInstallationsInstallationIdAccessTokensRequestBody> get copyWith => __$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWithImpl<_AppInstallationsInstallationIdAccessTokensRequestBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppInstallationsInstallationIdAccessTokensRequestBodyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppInstallationsInstallationIdAccessTokensRequestBody&&const DeepCollectionEquality().equals(other._repositories, _repositories)&&const DeepCollectionEquality().equals(other._repositoryIds, _repositoryIds)&&(identical(other.permissions, permissions) || other.permissions == permissions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_repositories),const DeepCollectionEquality().hash(_repositoryIds),permissions);

@override
String toString() {
  return 'AppInstallationsInstallationIdAccessTokensRequestBody(repositories: $repositories, repositoryIds: $repositoryIds, permissions: $permissions)';
}


}

/// @nodoc
abstract mixin class _$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWith<$Res> implements $AppInstallationsInstallationIdAccessTokensRequestBodyCopyWith<$Res> {
  factory _$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWith(_AppInstallationsInstallationIdAccessTokensRequestBody value, $Res Function(_AppInstallationsInstallationIdAccessTokensRequestBody) _then) = __$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWithImpl;
@override @useResult
$Res call({
 List<String>? repositories,@JsonKey(name: 'repository_ids') List<int>? repositoryIds, AppPermissions? permissions
});


@override $AppPermissionsCopyWith<$Res>? get permissions;

}
/// @nodoc
class __$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWithImpl<$Res>
    implements _$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWith<$Res> {
  __$AppInstallationsInstallationIdAccessTokensRequestBodyCopyWithImpl(this._self, this._then);

  final _AppInstallationsInstallationIdAccessTokensRequestBody _self;
  final $Res Function(_AppInstallationsInstallationIdAccessTokensRequestBody) _then;

/// Create a copy of AppInstallationsInstallationIdAccessTokensRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? repositories = freezed,Object? repositoryIds = freezed,Object? permissions = freezed,}) {
  return _then(_AppInstallationsInstallationIdAccessTokensRequestBody(
repositories: freezed == repositories ? _self._repositories : repositories // ignore: cast_nullable_to_non_nullable
as List<String>?,repositoryIds: freezed == repositoryIds ? _self._repositoryIds : repositoryIds // ignore: cast_nullable_to_non_nullable
as List<int>?,permissions: freezed == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as AppPermissions?,
  ));
}

/// Create a copy of AppInstallationsInstallationIdAccessTokensRequestBody
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
