// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repositories_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GitHubRepository {

 String get fullName; String get name; String get owner; bool get private; String get defaultBranch;
/// Create a copy of GitHubRepository
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubRepositoryCopyWith<GitHubRepository> get copyWith => _$GitHubRepositoryCopyWithImpl<GitHubRepository>(this as GitHubRepository, _$identity);

  /// Serializes this GitHubRepository to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubRepository&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.name, name) || other.name == name)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.private, private) || other.private == private)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fullName,name,owner,private,defaultBranch);

@override
String toString() {
  return 'GitHubRepository(fullName: $fullName, name: $name, owner: $owner, private: $private, defaultBranch: $defaultBranch)';
}


}

/// @nodoc
abstract mixin class $GitHubRepositoryCopyWith<$Res>  {
  factory $GitHubRepositoryCopyWith(GitHubRepository value, $Res Function(GitHubRepository) _then) = _$GitHubRepositoryCopyWithImpl;
@useResult
$Res call({
 String fullName, String name, String owner, bool private, String defaultBranch
});




}
/// @nodoc
class _$GitHubRepositoryCopyWithImpl<$Res>
    implements $GitHubRepositoryCopyWith<$Res> {
  _$GitHubRepositoryCopyWithImpl(this._self, this._then);

  final GitHubRepository _self;
  final $Res Function(GitHubRepository) _then;

/// Create a copy of GitHubRepository
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullName = null,Object? name = null,Object? owner = null,Object? private = null,Object? defaultBranch = null,}) {
  return _then(_self.copyWith(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,defaultBranch: null == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubRepository].
extension GitHubRepositoryPatterns on GitHubRepository {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubRepository value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubRepository() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubRepository value)  $default,){
final _that = this;
switch (_that) {
case _GitHubRepository():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubRepository value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubRepository() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullName,  String name,  String owner,  bool private,  String defaultBranch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubRepository() when $default != null:
return $default(_that.fullName,_that.name,_that.owner,_that.private,_that.defaultBranch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullName,  String name,  String owner,  bool private,  String defaultBranch)  $default,) {final _that = this;
switch (_that) {
case _GitHubRepository():
return $default(_that.fullName,_that.name,_that.owner,_that.private,_that.defaultBranch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullName,  String name,  String owner,  bool private,  String defaultBranch)?  $default,) {final _that = this;
switch (_that) {
case _GitHubRepository() when $default != null:
return $default(_that.fullName,_that.name,_that.owner,_that.private,_that.defaultBranch);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubRepository implements GitHubRepository {
  const _GitHubRepository({required this.fullName, required this.name, required this.owner, required this.private, required this.defaultBranch});
  factory _GitHubRepository.fromJson(Map<String, dynamic> json) => _$GitHubRepositoryFromJson(json);

@override final  String fullName;
@override final  String name;
@override final  String owner;
@override final  bool private;
@override final  String defaultBranch;

/// Create a copy of GitHubRepository
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubRepositoryCopyWith<_GitHubRepository> get copyWith => __$GitHubRepositoryCopyWithImpl<_GitHubRepository>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubRepositoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubRepository&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.name, name) || other.name == name)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.private, private) || other.private == private)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fullName,name,owner,private,defaultBranch);

@override
String toString() {
  return 'GitHubRepository(fullName: $fullName, name: $name, owner: $owner, private: $private, defaultBranch: $defaultBranch)';
}


}

/// @nodoc
abstract mixin class _$GitHubRepositoryCopyWith<$Res> implements $GitHubRepositoryCopyWith<$Res> {
  factory _$GitHubRepositoryCopyWith(_GitHubRepository value, $Res Function(_GitHubRepository) _then) = __$GitHubRepositoryCopyWithImpl;
@override @useResult
$Res call({
 String fullName, String name, String owner, bool private, String defaultBranch
});




}
/// @nodoc
class __$GitHubRepositoryCopyWithImpl<$Res>
    implements _$GitHubRepositoryCopyWith<$Res> {
  __$GitHubRepositoryCopyWithImpl(this._self, this._then);

  final _GitHubRepository _self;
  final $Res Function(_GitHubRepository) _then;

/// Create a copy of GitHubRepository
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullName = null,Object? name = null,Object? owner = null,Object? private = null,Object? defaultBranch = null,}) {
  return _then(_GitHubRepository(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,defaultBranch: null == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
