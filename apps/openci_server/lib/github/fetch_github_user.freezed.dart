// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fetch_github_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GitHubUser {

 int get id; String get login;
/// Create a copy of GitHubUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubUserCopyWith<GitHubUser> get copyWith => _$GitHubUserCopyWithImpl<GitHubUser>(this as GitHubUser, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubUser&&(identical(other.id, id) || other.id == id)&&(identical(other.login, login) || other.login == login));
}


@override
int get hashCode => Object.hash(runtimeType,id,login);

@override
String toString() {
  return 'GitHubUser(id: $id, login: $login)';
}


}

/// @nodoc
abstract mixin class $GitHubUserCopyWith<$Res>  {
  factory $GitHubUserCopyWith(GitHubUser value, $Res Function(GitHubUser) _then) = _$GitHubUserCopyWithImpl;
@useResult
$Res call({
 int id, String login
});




}
/// @nodoc
class _$GitHubUserCopyWithImpl<$Res>
    implements $GitHubUserCopyWith<$Res> {
  _$GitHubUserCopyWithImpl(this._self, this._then);

  final GitHubUser _self;
  final $Res Function(GitHubUser) _then;

/// Create a copy of GitHubUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? login = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubUser].
extension GitHubUserPatterns on GitHubUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubUser value)  $default,){
final _that = this;
switch (_that) {
case _GitHubUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubUser value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String login)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubUser() when $default != null:
return $default(_that.id,_that.login);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String login)  $default,) {final _that = this;
switch (_that) {
case _GitHubUser():
return $default(_that.id,_that.login);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String login)?  $default,) {final _that = this;
switch (_that) {
case _GitHubUser() when $default != null:
return $default(_that.id,_that.login);case _:
  return null;

}
}

}

/// @nodoc


class _GitHubUser implements GitHubUser {
  const _GitHubUser({required this.id, required this.login});


@override final  int id;
@override final  String login;

/// Create a copy of GitHubUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubUserCopyWith<_GitHubUser> get copyWith => __$GitHubUserCopyWithImpl<_GitHubUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubUser&&(identical(other.id, id) || other.id == id)&&(identical(other.login, login) || other.login == login));
}


@override
int get hashCode => Object.hash(runtimeType,id,login);

@override
String toString() {
  return 'GitHubUser(id: $id, login: $login)';
}


}

/// @nodoc
abstract mixin class _$GitHubUserCopyWith<$Res> implements $GitHubUserCopyWith<$Res> {
  factory _$GitHubUserCopyWith(_GitHubUser value, $Res Function(_GitHubUser) _then) = __$GitHubUserCopyWithImpl;
@override @useResult
$Res call({
 int id, String login
});




}
/// @nodoc
class __$GitHubUserCopyWithImpl<$Res>
    implements _$GitHubUserCopyWith<$Res> {
  __$GitHubUserCopyWithImpl(this._self, this._then);

  final _GitHubUser _self;
  final $Res Function(_GitHubUser) _then;

/// Create a copy of GitHubUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? login = null,}) {
  return _then(_GitHubUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
